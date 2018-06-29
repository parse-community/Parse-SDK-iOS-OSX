/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFQueryUtilities.h"

#import "PFAssert.h"
#import "PFConstants.h"
#import "PFErrorUtilities.h"

@implementation PFQueryUtilities

///--------------------------------------
#pragma mark - Predicate
///--------------------------------------

+ (NSPredicate *)predicateByNormalizingPredicate:(NSPredicate *)predicate {
    return [self _hoistCommonPredicates:[self _normalizeToDNF:predicate]];
}

/**
 Traverses over all of the subpredicates in the given predicate, calling the given blocks to
 transform any instances of NSPredicate.
 */
+ (NSPredicate *)_mapPredicate:(NSPredicate *)predicate
                 compoundBlock:(NSPredicate *(^)(NSCompoundPredicate *))compoundBlock
               comparisonBlock:(NSPredicate *(^)(NSComparisonPredicate *predicate))comparisonBlock {
    if ([predicate isKindOfClass:[NSCompoundPredicate class]]) {
        if (compoundBlock) {
            return compoundBlock((NSCompoundPredicate *)predicate);
        } else {
            NSCompoundPredicate *compound = (NSCompoundPredicate *)predicate;

            NSMutableArray *newSubpredicates = [NSMutableArray arrayWithCapacity:compound.subpredicates.count];
            for (NSPredicate *subPredicate in compound.subpredicates) {
                [newSubpredicates addObject:[self _mapPredicate:subPredicate
                                                  compoundBlock:compoundBlock
                                                comparisonBlock:comparisonBlock]];
            }

            NSCompoundPredicateType type = compound.compoundPredicateType;
            return [[NSCompoundPredicate alloc] initWithType:type subpredicates:newSubpredicates];
        }
    }
    if ([predicate isKindOfClass:[NSComparisonPredicate class]]) {
        if (comparisonBlock) {
            return comparisonBlock((NSComparisonPredicate *)predicate);
        } else {
            return predicate;
        }
    }
    PFConsistencyAssertionFailure(@"NSExpression predicates are not supported.");
    return nil;
}

/**
 Returns a predicate that is the negation of the input predicate, or throws on error.
 */
+ (NSPredicate *)_negatePredicate:(NSPredicate *)predicate {
    return [self _mapPredicate:predicate
                 compoundBlock:^NSPredicate *(NSCompoundPredicate *compound) {
                     switch (compound.compoundPredicateType) {
                         case NSNotPredicateType: {
                             return compound.subpredicates[0];
                         }
                         case NSAndPredicateType: {
                             NSMutableArray *newSubpredicates =
                             [NSMutableArray arrayWithCapacity:compound.subpredicates.count];
                             for (NSPredicate *subpredicate in compound.subpredicates) {
                                 [newSubpredicates addObject:[self _negatePredicate:subpredicate]];
                             }
                             return [NSCompoundPredicate orPredicateWithSubpredicates:newSubpredicates];
                         }
                         case NSOrPredicateType: {
                             NSMutableArray *newSubpredicates =
                             [NSMutableArray arrayWithCapacity:compound.subpredicates.count];
                             for (NSPredicate *subpredicate in compound.subpredicates) {
                                 [newSubpredicates addObject:[self _negatePredicate:subpredicate]];
                             }
                             return [NSCompoundPredicate andPredicateWithSubpredicates:newSubpredicates];
                         }
                         default: {
                             PFConsistencyAssertionFailure(@"This compound predicate cannot be negated. (%ld)",
                                                           (unsigned long)compound.compoundPredicateType);
                             return nil;
                         }
                     }
                 } comparisonBlock:^NSPredicate *(NSComparisonPredicate *comparison) {
                     NSPredicateOperatorType newType;
                     NSComparisonPredicateModifier newModifier = comparison.comparisonPredicateModifier;
                     SEL customSelector = NULL;

                     switch (comparison.predicateOperatorType) {
                         case NSEqualToPredicateOperatorType: {
                             newType = NSNotEqualToPredicateOperatorType;
                             break;
                         }
                         case NSNotEqualToPredicateOperatorType: {
                             newType = NSEqualToPredicateOperatorType;
                             break;
                         }
                         case NSInPredicateOperatorType: {
                             newType = NSCustomSelectorPredicateOperatorType;
                             customSelector = NSSelectorFromString(@"notContainedIn:");
                             break;
                         }
                         case NSLessThanPredicateOperatorType: {
                             newType = NSGreaterThanOrEqualToPredicateOperatorType;
                             break;
                         }
                         case NSLessThanOrEqualToPredicateOperatorType: {
                             newType = NSGreaterThanPredicateOperatorType;
                             break;
                         }
                         case NSGreaterThanPredicateOperatorType: {
                             newType = NSLessThanOrEqualToPredicateOperatorType;
                             break;
                         }
                         case NSGreaterThanOrEqualToPredicateOperatorType: {
                             newType = NSLessThanPredicateOperatorType;
                             break;
                         }
                         case NSBetweenPredicateOperatorType: {
                             PFConsistencyAssertionFailure(@"A BETWEEN predicate was found after they should have been removed.");
                         }
                         case NSMatchesPredicateOperatorType:
                         case NSLikePredicateOperatorType:
                         case NSBeginsWithPredicateOperatorType:
                         case NSEndsWithPredicateOperatorType:
                         case NSContainsPredicateOperatorType:
                         case NSCustomSelectorPredicateOperatorType:
                         default: {
                             PFConsistencyAssertionFailure(@"This comparison predicate cannot be negated. (%@)", comparison);
                             return nil;
                         }
                     }

                     if (newType == NSCustomSelectorPredicateOperatorType) {
                         return [NSComparisonPredicate predicateWithLeftExpression:comparison.leftExpression
                                                                   rightExpression:comparison.rightExpression
                                                                    customSelector:customSelector];
                     } else {
                         return [NSComparisonPredicate predicateWithLeftExpression:comparison.leftExpression
                                                                   rightExpression:comparison.rightExpression
                                                                          modifier:newModifier
                                                                              type:newType
                                                                           options:comparison.options];
                     }
                 }];
}

/**
 Returns a version of the given predicate that contains no NSNotPredicateType compound predicates.
 This greatly simplifies the diversity of predicates we have to handle later in the pipeline.
 */
+ (NSPredicate *)removeNegation:(NSPredicate *)predicate {
    return [self _mapPredicate:predicate
                 compoundBlock:^NSPredicate *(NSCompoundPredicate *compound) {
                     // Remove negation from any subpredicates.
                     NSMutableArray *newSubpredicates =
                     [NSMutableArray arrayWithCapacity:compound.subpredicates.count];
                     for (NSPredicate *subPredicate in compound.subpredicates) {
                         [newSubpredicates addObject:[self removeNegation:subPredicate]];
                     }

                     // If this is a NOT predicate, return the negation of the subpredicate.
                     // Otherwise, just pass it on.
                     if (compound.compoundPredicateType == NSNotPredicateType) {
                         return [self _negatePredicate:newSubpredicates[0]];
                     } else {
                         return [[NSCompoundPredicate alloc] initWithType:compound.compoundPredicateType
                                                            subpredicates:newSubpredicates];
                     }
                 } comparisonBlock:nil];
}

/**
 Returns a version of the given predicate that contains no NSBetweenPredicateOperatorType predicates.
 (A BETWEEN {C, D}) gets converted to (A >= C AND A <= D).
 */
+ (NSPredicate *)removeBetween:(NSPredicate *)predicate {
    return [self _mapPredicate:predicate
                 compoundBlock:nil
               comparisonBlock:^NSPredicate *(NSComparisonPredicate *predicate) {
                   if (predicate.predicateOperatorType == NSBetweenPredicateOperatorType) {
                       NSComparisonPredicate *between = (NSComparisonPredicate *)predicate;
                       NSExpression *rhs = between.rightExpression;

                       PFConsistencyAssert(rhs.expressionType == NSConstantValueExpressionType ||
                                           rhs.expressionType == NSAggregateExpressionType,
                                           @"The right-hand side of a BETWEEN operation must be a value or literal.");

                       PFConsistencyAssert([rhs.constantValue isKindOfClass:[NSArray class]],
                                           @"The right-hand side of a BETWEEN operation must be an array.");

                       NSArray *array = rhs.constantValue;
                       PFConsistencyAssert(array.count == 2, @"The right-hand side of a BETWEEN operation must have 2 items.");

                       id minValue = array[0];
                       id maxValue = array[1];

                       NSExpression *minExpression = ([minValue isKindOfClass:[NSExpression class]]
                                                      ? minValue
                                                      : [NSExpression expressionForConstantValue:minValue]);
                       NSExpression *maxExpression = ([maxValue isKindOfClass:[NSExpression class]]
                                                      ? maxValue
                                                      : [NSExpression expressionForConstantValue:maxValue]);

                       return [NSCompoundPredicate andPredicateWithSubpredicates:
                               @[ [NSComparisonPredicate predicateWithLeftExpression:between.leftExpression
                                                                     rightExpression:minExpression
                                                                            modifier:between.comparisonPredicateModifier
                                                                                type:NSGreaterThanOrEqualToPredicateOperatorType
                                                                             options:between.options],
                                  [NSComparisonPredicate predicateWithLeftExpression:between.leftExpression
                                                                     rightExpression:maxExpression
                                                                            modifier:between.comparisonPredicateModifier
                                                                                type:NSLessThanOrEqualToPredicateOperatorType
                                                                             options:between.options]
                                  ]];
                   }
                   return predicate;
               }];
}

/**
 Returns a version of the given predicate that contains no Yoda conditions.
 A Yoda condition is one where there's a constant on the LHS, such as (3 <= X).
 The predicate returned by this method will instead have (X >= 3).
 */
+ (NSPredicate *)reverseYodaConditions:(NSPredicate *)predicate {
    return [self _mapPredicate:predicate
                 compoundBlock:nil
               comparisonBlock:^NSPredicate *(NSComparisonPredicate *comparison) {
                   if (comparison.leftExpression.expressionType == NSConstantValueExpressionType &&
                       comparison.rightExpression.expressionType == NSKeyPathExpressionType) {
                       // This is a Yoda condition.
                       NSPredicateOperatorType newType;
                       switch (comparison.predicateOperatorType) {
                           case NSEqualToPredicateOperatorType: {
                               newType = NSEqualToPredicateOperatorType;
                               break;
                           }
                           case NSNotEqualToPredicateOperatorType: {
                               newType = NSNotEqualToPredicateOperatorType;
                               break;
                           }
                           case NSLessThanPredicateOperatorType: {
                               newType = NSGreaterThanPredicateOperatorType;
                               break;
                           }
                           case NSLessThanOrEqualToPredicateOperatorType: {
                               newType = NSGreaterThanOrEqualToPredicateOperatorType;
                               break;
                           }
                           case NSGreaterThanPredicateOperatorType: {
                               newType = NSLessThanPredicateOperatorType;
                               break;
                           }
                           case NSGreaterThanOrEqualToPredicateOperatorType: {
                               newType = NSLessThanOrEqualToPredicateOperatorType;
                               break;
                           }
                           case NSInPredicateOperatorType: {
                               // This is like "5 IN X" where X is an array.
                               // Mongo handles this with syntax like "X = 5".
                               newType = NSEqualToPredicateOperatorType;
                               break;
                           }
                           case NSContainsPredicateOperatorType:
                           case NSMatchesPredicateOperatorType:
                           case NSLikePredicateOperatorType:
                           case NSBeginsWithPredicateOperatorType:
                           case NSEndsWithPredicateOperatorType:
                           case NSCustomSelectorPredicateOperatorType:
                           case NSBetweenPredicateOperatorType:
                           default: {
                               // We don't know how to reverse this Yoda condition, but maybe that's okay.
                               return predicate;
                           }
                       }
                       return [NSComparisonPredicate predicateWithLeftExpression:comparison.rightExpression
                                                                 rightExpression:comparison.leftExpression
                                                                        modifier:comparison.comparisonPredicateModifier
                                                                            type:newType
                                                                         options:comparison.options];
                   }
                   return comparison;
               }];
}

/**
 Returns a version of the given predicate converted to disjunctive normal form (DNF).
 Unlike normalizeToDNF:error:, this method only accepts compound predicates, and assumes that
 removeNegation:error: has already been applied to the given predicate.
 */
+ (NSPredicate *)asOrOfAnds:(NSCompoundPredicate *)compound {
    // Convert the sub-predicates to DNF.
    NSMutableArray *dnfSubpredicates = [NSMutableArray arrayWithCapacity:compound.subpredicates.count];
    for (NSPredicate *subpredicate in compound.subpredicates) {
        if ([subpredicate isKindOfClass:[NSCompoundPredicate class]]) {
            [dnfSubpredicates addObject:[self asOrOfAnds:(NSCompoundPredicate *)subpredicate]];
        } else {
            [dnfSubpredicates addObject:subpredicate];
        }
    }

    if (compound.compoundPredicateType == NSOrPredicateType) {
        // We just need to flatten any child ORs into this OR.
        NSMutableArray *newSubpredicates = [NSMutableArray arrayWithCapacity:dnfSubpredicates.count];
        for (NSPredicate *subpredicate in dnfSubpredicates) {
            if ([subpredicate isKindOfClass:[NSCompoundPredicate class]] &&
                ((NSCompoundPredicate *)subpredicate).compoundPredicateType == NSOrPredicateType) {
                for (NSPredicate *grandchild in ((NSCompoundPredicate *)subpredicate).subpredicates) {
                    [newSubpredicates addObject:grandchild];
                }
            } else {
                [newSubpredicates addObject:subpredicate];
            }
        }
        // There's no reason to wrap a single predicate in an OR.
        if (newSubpredicates.count == 1) {
            return newSubpredicates.lastObject;
        }
        return [NSCompoundPredicate orPredicateWithSubpredicates:newSubpredicates];
    }

    if (compound.compoundPredicateType == NSAndPredicateType) {
        // This is tough. We need to take the cross product of all the subpredicates.
        NSMutableArray *disjunction = [NSMutableArray arrayWithObject:@[]];
        for (NSPredicate *subpredicate in dnfSubpredicates) {
            NSMutableArray *newDisjunction = [NSMutableArray array];
            if ([subpredicate isKindOfClass:[NSCompoundPredicate class]]) {
                NSCompoundPredicate *subcompound = (NSCompoundPredicate *)subpredicate;
                if (subcompound.compoundPredicateType == NSOrPredicateType) {
                    // We have to add every item in the OR to every AND list we have.
                    for (NSArray *conjunction in disjunction) {
                        for (NSPredicate *grandchild in subcompound.subpredicates) {
                            [newDisjunction addObject:[conjunction arrayByAddingObject:grandchild]];
                        }
                    }

                } else if (subcompound.compoundPredicateType == NSAndPredicateType) {
                    // Just add all these conditions to all the conjunctions in progress.
                    for (NSArray *conjunction in disjunction) {
                        NSArray *grandchildren = subcompound.subpredicates;
                        [newDisjunction addObject:[conjunction arrayByAddingObjectsFromArray:grandchildren]];
                    }

                } else {
                    PFConsistencyAssertionFailure(@"[PFQuery asOrOfAnds:] found a compound query that wasn't OR or AND.");
                }
            } else {
                // Just add this condition to all the conjunctions in progress.
                for (NSArray *conjunction in disjunction) {
                    [newDisjunction addObject:[conjunction arrayByAddingObject:subpredicate]];
                }
            }
            disjunction = newDisjunction;
        }

        // Now disjunction contains an OR of ANDs. We just need to convert it to NSPredicates.
        NSMutableArray *andPredicates = [NSMutableArray arrayWithCapacity:disjunction.count];
        for (NSArray *conjunction in disjunction) {
            if (conjunction.count > 0) {
                if (conjunction.count == 1) {
                    [andPredicates addObject:conjunction.lastObject];
                } else {
                    [andPredicates addObject:[NSCompoundPredicate
                                              andPredicateWithSubpredicates:conjunction]];
                }
            }
        }
        if (andPredicates.count == 1) {
            return andPredicates.lastObject;
        } else {
            return [NSCompoundPredicate orPredicateWithSubpredicates:andPredicates];
        }
    }
    PFConsistencyAssertionFailure(@"[PFQuery asOrOfAnds:] was passed a compound query that wasn't OR or AND.");
    return nil;
}

/**
 Throws an exception if any comparison predicate inside this predicate has any modifiers, such as ANY, EVERY, etc.
 */
+ (void)assertNoPredicateModifiers:(NSPredicate *)predicate {
    [self _mapPredicate:predicate
          compoundBlock:nil
        comparisonBlock:^NSPredicate *(NSComparisonPredicate *comparison) {
            PFConsistencyAssert(comparison.comparisonPredicateModifier == NSDirectPredicateModifier,
                                @"Unsupported comparison predicate modifier %ld.",
                                (unsigned long)comparison.comparisonPredicateModifier);
            return comparison;
        }];
}

/**
 Returns a version of the given predicate converted to disjunctive normal form (DNF),
 known colloqially as an "or of ands", the only form of query that PFQuery accepts.
 */
+ (NSPredicate *)_normalizeToDNF:(NSPredicate *)predicate {
    // Make sure they didn't use ANY, EVERY, etc.
    [self assertNoPredicateModifiers:predicate];

    // Change any BETWEEN operators to a conjunction.
    predicate = [self removeBetween:predicate];

    // Change any backwards (3 <= X) to the standardized (X >= 3).
    predicate = [self reverseYodaConditions:predicate];

    // Push any negation into the leaves.
    predicate = [self removeNegation:predicate];

    // Any comparison predicate is trivially DNF.
    if (![predicate isKindOfClass:[NSCompoundPredicate class]]) {
        return predicate;
    }

    // It must be a compound predicate. Convert it to an OR of ANDs.
    return [self asOrOfAnds:(NSCompoundPredicate *)predicate];
}

/**
 Takes a predicate like ((A AND B) OR (A AND C)) and rewrites it as the more efficient (A AND (B OR C)).
 Assumes the input predicate is already in DNF.
 // TODO: (nlutsenko): Move this logic into the server and remove it from here.
 */
+ (NSPredicate *)_hoistCommonPredicates:(NSPredicate *)predicate {
    // This only makes sense for queries with a top-level OR.
    if (!([predicate isKindOfClass:[NSCompoundPredicate class]] &&
          ((NSCompoundPredicate *)predicate).compoundPredicateType == NSOrPredicateType)) {
        return predicate;
    }

    // Find the set of predicates that are included in every branch of this OR.
    NSArray *andPredicates = ((NSCompoundPredicate *)predicate).subpredicates;
    NSMutableSet *common = nil;
    for (NSPredicate *andPredicate in andPredicates) {
        NSMutableSet *comparisonPredicates = nil;
        if ([andPredicate isKindOfClass:[NSComparisonPredicate class]]) {
            comparisonPredicates = [NSMutableSet setWithObject:andPredicate];
        } else {
            comparisonPredicates =
            [NSMutableSet setWithArray:((NSCompoundPredicate *)andPredicate).subpredicates];
        }

        if (!common) {
            common = comparisonPredicates;
        } else {
            [common intersectSet:comparisonPredicates];
        }
    }

    if (!common.count) {
        return predicate;
    }

    NSMutableArray *newAndPredicates = [NSMutableArray array];

    // Okay, there were common sub-predicates. Hoist them up to this one.
    for (NSPredicate *andPredicate in andPredicates) {
        NSMutableSet *comparisonPredicates = nil;
        if ([andPredicate isKindOfClass:[NSComparisonPredicate class]]) {
            comparisonPredicates = [NSMutableSet setWithObject:andPredicate];
        } else {
            comparisonPredicates =
            [NSMutableSet setWithArray:((NSCompoundPredicate *)andPredicate).subpredicates];
        }

        for (NSPredicate *comparisonPredicate in common) {
            [comparisonPredicates removeObject:comparisonPredicate];
        }

        if (comparisonPredicates.count == 0) {
            // One of the OR predicates reduces to TRUE, so just return the hoisted part.
            return [NSCompoundPredicate andPredicateWithSubpredicates:common.allObjects];
        } else if (comparisonPredicates.count == 1) {
            [newAndPredicates addObject:comparisonPredicates.allObjects.lastObject];
        } else {
            NSPredicate *newAndPredicate =
            [NSCompoundPredicate andPredicateWithSubpredicates:comparisonPredicates.allObjects];
            [newAndPredicates addObject:newAndPredicate];
        }
    }

    // Make an AND of the hoisted predicates and the OR of the modified subpredicates.
    NSPredicate *newOrPredicate = [NSCompoundPredicate orPredicateWithSubpredicates:newAndPredicates];
    NSArray *newPredicates = [@[ newOrPredicate ] arrayByAddingObjectsFromArray:common.allObjects];
    return [NSCompoundPredicate andPredicateWithSubpredicates:newPredicates];
}

///--------------------------------------
#pragma mark - Regex
///--------------------------------------

/**
 This is used to create a regex string to match the input string. By using Q and E flags to match, we can do this
 without requiring super expensive rewrites, but me must be careful to escape existing \E flags in the input string.
 By replacing it with `\E\\E\Q`, the regex engine will end the old literal block, put in the user's `\E` string, and
 Begin another literal block.
 */
+ (NSString *)regexStringForString:(NSString *)string {
    return [NSString stringWithFormat:@"\\Q%@\\E", [string stringByReplacingOccurrencesOfString:@"\\E"
                                                                                     withString:@"\\E\\\\E\\Q"]];
}

///--------------------------------------
#pragma mark - Errors
///--------------------------------------

+ (NSError *)objectNotFoundError {
    return [PFErrorUtilities errorWithCode:kPFErrorObjectNotFound message:@"No results matched the query."];
}

@end
