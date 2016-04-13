/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFOfflineQueryLogic.h"

#import <Bolts/BFTask.h>
#import <Bolts/BFExecutor.h>

#import "PFACL.h"
#import "PFAssert.h"
#import "PFConstants.h"
#import "PFDateFormatter.h"
#import "PFDecoder.h"
#import "PFEncoder.h"
#import "PFErrorUtilities.h"
#import "PFGeoPoint.h"
#import "PFOfflineStore.h"
#import "PFQueryPrivate.h"
#import "PFRelation.h"
#import "PFRelationPrivate.h"
#import "PFQueryConstants.h"

typedef BOOL (^PFComparatorDeciderBlock)(id value, id constraint);
typedef BOOL (^PFSubQueryMatcherBlock)(id object, NSArray *results);

/**
 A query to be used in $inQuery, $notInQuery, $select and $dontSelect
 */
@interface PFSubQueryMatcher : NSObject

@property (nonatomic, strong, readonly) PFQuery *subQuery;
@property (nonatomic, strong) BFTask *subQueryResults;
@property (nonatomic, strong, readonly) PFOfflineStore *offlineStore;

@end

@implementation PFSubQueryMatcher

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)initWithSubQuery:(PFQuery *)query offlineStore:(PFOfflineStore *)offlineStore {
    if ((self = [super init]) != nil) {
        _subQuery = query;
        _offlineStore = offlineStore;
    }

    return self;
}

///--------------------------------------
#pragma mark - SubQuery Matcher Creator
///--------------------------------------

- (PFConstraintMatcherBlock)createMatcherWithSubQueryMatcherBlock:(PFSubQueryMatcherBlock)block user:(PFUser *)user {
    return ^BFTask *(PFObject *object, PFSQLiteDatabase *database) {
        if (self.subQueryResults == nil) {
            self.subQueryResults = [self.offlineStore findAsyncForQueryState:self.subQuery.state
                                                                        user:user
                                                                         pin:nil
                                                                     isCount:NO
                                                                    database:database];
        }
        return [self.subQueryResults continueWithSuccessBlock:^id(BFTask *task) {
            return @(block(object, task.result));
        }];
    };
}

@end

@interface PFOfflineQueryLogic ()

@property (nonatomic, weak) PFOfflineStore *offlineStore;

@end

@implementation PFOfflineQueryLogic

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)initWithOfflineStore:(PFOfflineStore *)offlineStore {
    if ((self = [super init]) != nil) {
        _offlineStore = offlineStore;
    }
    return self;
}

///--------------------------------------
#pragma mark - Value Getter
///--------------------------------------

- (id)valueForContainer:(id)container
                    key:(NSString *)key {
    return [self valueForContainer:container key:key depth:0];
}

- (id)valueForContainer:(id)container
                    key:(NSString *)key
                  depth:(int)depth {
    if ([key rangeOfString:@"."].location != NSNotFound) {
        NSArray *parts = [key componentsSeparatedByString:@"."];

        NSString *firstKey = parts.firstObject;
        NSString *rest = nil;
        if (parts.count > 1) {
            NSRange range = NSMakeRange(1, parts.count - 1);
            rest = [[parts subarrayWithRange:range] componentsJoinedByString:@"."];
        }
        id value = [self valueForContainer:container key:firstKey depth:depth + 1];
        // Only NSDictionary can be dotted into for getting values, so we should reject
        // anything like ParseObjects and arrays.
        if (!(value == nil || [value isKindOfClass:[NSDictionary class]])) {
            if (depth > 0) {
                id restFormat = [[PFPointerObjectEncoder objectEncoder] encodeObject:value];
                if ([restFormat isKindOfClass:[NSDictionary class]]) {
                    return [self valueForContainer:restFormat key:rest depth:depth + 1];
                }
            }
            PFParameterAssertionFailure(@"Key %@ is invalid.", key);
        }
        return [self valueForContainer:value key:rest depth:depth + 1];
    }

    if ([container isKindOfClass:[PFObject class]]) {
        PFObject *object = (PFObject *)container;

        // The object needs to have been fetched already if we are going to sort by one of its field.
        PFParameterAssert(object.dataAvailable, @"Bad key %@", key);

        // Handle special keys for PFObject.
        if ([key isEqualToString:@"objectId"]) {
            return object.objectId;
        } else if ([key isEqualToString:@"createdAt"] || [key isEqualToString:@"_created_at"]) {
            return object.createdAt;
        } else if ([key isEqualToString:@"updatedAt"] || [key isEqualToString:@"_updated_at"]) {
            return object.updatedAt;
        } else {
            return object[key];
        }
    } else if ([container isKindOfClass:[NSDictionary class]]) {
        return ((NSDictionary *)container)[key];
    } else if (container == nil) {
        return nil;
    } else {
        PFParameterAssertionFailure(@"Bad key %@", key);
        // Shouldn't reach here.
        return nil;
    }
}

///--------------------------------------
#pragma mark - Matcher With Decider
///--------------------------------------

/**
 Returns YES if decider returns YES for any value in the given array.
 */
+ (BOOL)matchesArray:(NSArray *)array
          constraint:(id)constraint
         withDecider:(PFComparatorDeciderBlock)decider {
    for (id value in array) {
        if (decider(value, constraint)) {
            return YES;
        }
    }
    return NO;
}

/**
 Returns YES if decider returns YES for any value in the given array.
 */
+ (BOOL)matchesValue:(id)value
          constraint:(id)constraint
         withDecider:(PFComparatorDeciderBlock)decider {
    if ([value isKindOfClass:[NSArray class]]) {
        return [self matchesArray:value constraint:constraint withDecider:decider];
    } else {
        return decider(value, constraint);
    }
}

///--------------------------------------
#pragma mark - Matcher
///--------------------------------------

/**
 Implements simple equality constraints. This emulates Mongo's behavior where "equals" can mean array containment.
 */
+ (BOOL)matchesValue:(id)value
             equalTo:(id)constraint {
    return [self matchesValue:value constraint:constraint withDecider:^BOOL (id value, id constraint) {
        // Do custom matching for dates to make sure we have proper precision.
        if ([value isKindOfClass:[NSDate class]] &&
            [constraint isKindOfClass:[NSDate class]]) {
            PFDateFormatter *dateFormatter = [PFDateFormatter sharedFormatter];
            NSString *valueString = [dateFormatter preciseStringFromDate:value];
            NSString *constraintString = [dateFormatter preciseStringFromDate:constraint];
            return [valueString isEqual:constraintString];
        }

        if ([value isKindOfClass:[PFRelation class]]) {
            return [value isEqual:constraint] || [value _hasKnownObject:constraint];
        }

        return [value isEqual:constraint];
    }];
}

/**
 Matches $ne constraints.
 */
+ (BOOL)matchesValue:(id)value
          notEqualTo:(id)constraint {
    return ![self matchesValue:value equalTo:constraint];
}

/**
 Matches $lt constraints.
 */
+ (BOOL)matchesValue:(id)value
            lessThan:(id)constraint {
    return [self matchesValue:value constraint:constraint withDecider:^BOOL (id value, id constraint) {
        if (value == nil || value == [NSNull null]) {
            return NO;
        }
        NSComparisonResult comparisonResult = [value compare:constraint];
        return comparisonResult == NSOrderedAscending;
    }];
}

/**
 Matches $lte constraints.
 */
+ (BOOL)matchesValue:(id)value
   lessThanOrEqualTo:(id)constraint {
    return [self matchesValue:value constraint:constraint withDecider:^BOOL (id value, id constraint) {
        if (value == nil || value == [NSNull null]) {
            return NO;
        }
        NSComparisonResult comparisonResult = [value compare:constraint];
        return (comparisonResult == NSOrderedAscending) || (comparisonResult == NSOrderedSame);
    }];
}

/**
 Matches $gt constraints.
 */
+ (BOOL)matchesValue:(id)value
         greaterThan:(id)constraint {
    return [self matchesValue:value constraint:constraint withDecider:^BOOL (id value, id constraint) {
        if (value == nil || value == [NSNull null]) {
            return NO;
        }
        NSComparisonResult comparisonResult = [value compare:constraint];
        return comparisonResult == NSOrderedDescending;
    }];
}

/**
 Matches $gte constraints.
 */
+ (BOOL)matchesValue:(id)value
greaterThanOrEqualTo:(id)constraint {
    return [self matchesValue:value constraint:constraint withDecider:^BOOL (id value, id constraint) {
        if (value == nil || value == [NSNull null]) {
            return NO;
        }
        NSComparisonResult comparisonResult = [value compare:constraint];
        return (comparisonResult == NSOrderedDescending) || (comparisonResult == NSOrderedSame);
    }];
}

/**
 Matches $in constraints.
 $in returns YES if the intersection of value and constraint is not an empty set.
 */
+ (BOOL)matchesValue:(id)value
         containedIn:(id)constraint {
    if (constraint == nil || constraint == [NSNull null]) {
        return NO;
    }

    PFParameterAssert([constraint isKindOfClass:[NSArray class]], @"Constraint type not supported for $in queries");

    for (id requiredItem in (NSArray *)constraint) {
        if ([self matchesValue:value equalTo:requiredItem]) {
            return YES;
        }
    }
    return NO;
}

/**
 Matches $nin constraints.
 */
+ (BOOL)matchesValue:(id)value
      notContainedIn:(id)constraint {
    return ![self matchesValue:value containedIn:constraint];
}

/**
 Matches $all constraints.
 */
+ (BOOL)matchesValue:(id)value containsAllObjectsInArray:(id)constraints {
    PFParameterAssert([constraints isKindOfClass:[NSArray class]], @"Constraint type not supported for $all queries");
    PFParameterAssert([value isKindOfClass:[NSArray class]], @"Value type not supported for $all queries");

    for (id requiredItem in (NSArray *)constraints) {
        if (![self matchesValue:value equalTo:requiredItem]) {
            return NO;
        }
    }
    return YES;
}

/**
 Matches $regex constraints.
 */
+ (BOOL)matchesValue:(id)value
               regex:(id)constraint
         withOptions:(NSString *)options {
    if (value == nil || value == [NSNull null]) {
        return NO;
    }

    if (options == nil) {
        options = @"";
    }

    PFParameterAssert([options rangeOfString:@"^[imxs]*$" options:NSRegularExpressionSearch].location != NSNotFound,
                      @"Invalid regex options %@", options);

    NSRegularExpressionOptions flags = 0;
    if ([options rangeOfString:@"i"].location != NSNotFound) {
        flags = flags | NSRegularExpressionCaseInsensitive;
    }
    if ([options rangeOfString:@"m"].location != NSNotFound) {
        flags = flags | NSRegularExpressionAnchorsMatchLines;
    }
    if ([options rangeOfString:@"x"].location != NSNotFound) {
        flags = flags | NSRegularExpressionAllowCommentsAndWhitespace;
    }
    if ([options rangeOfString:@"s"].location != NSNotFound) {
        flags = flags | NSRegularExpressionDotMatchesLineSeparators;
    }

    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:constraint
                                                                           options:flags
                                                                             error:&error];
    NSArray *matches = [regex matchesInString:value options:0 range:NSMakeRange(0, [value length])];
    return matches.count > 0;
}

/**
 Matches $exists constraints.
 */
+ (BOOL)matchesValue:(id)value
              exists:(id)constraint {
    if (constraint != nil && [constraint boolValue]) {
        return value != nil && value != [NSNull null];
    }

    return value == nil || value == [NSNull null];
}

/**
 Matches $nearSphere constraints.
 */
+ (BOOL)matchesValue:(id)value
          nearSphere:(id)constraint
         maxDistance:(NSNumber *)maxDistance {
    if (value == nil || value == [NSNull null]) {
        return NO;
    }
    if (maxDistance == nil) {
        return YES;
    }
    PFGeoPoint *point1 = constraint;
    PFGeoPoint *point2 = value;
    return [point1 distanceInRadiansTo:point2] <= maxDistance.doubleValue;
}

/**
 Matches $within constraints.
 */
+ (BOOL)matchesValue:(id)value
              within:(id)constraint {
    NSDictionary *constraintDictionary = (NSDictionary *)constraint;
    NSArray *box = constraintDictionary[PFQueryOptionKeyBox];
    PFGeoPoint *southWest = box[0];
    PFGeoPoint *northEast = box[1];
    PFGeoPoint *target = (PFGeoPoint *)value;

    PFParameterAssert(northEast.longitude >= southWest.longitude,
                      @"whereWithinGeoBox queries cannot cross the International Date Line.");
    PFParameterAssert(northEast.latitude >= southWest.latitude,
                      @"The southwest corner of a geo box must be south of the northeast corner.");
    PFParameterAssert((northEast.longitude - southWest.longitude) <= 180,
                      @"Geo box queries larger than 180 degrees in longitude are not supported."
                      @"Please check point order.");

    return (target.latitude >= southWest.latitude &&
            target.latitude <= northEast.latitude &&
            target.longitude >= southWest.longitude &&
            target.longitude <= northEast.longitude);
}

/**
 Returns YES iff the given value matches the given operator and constraint.
 Raise NSInvalidArgumentException if the operator is not one this function can handle
 */
+ (BOOL)matchesValue:(id)value
          constraint:(id)constraint
            operator:(NSString *)operator
   allKeyConstraints:(NSDictionary *)allKeyConstraints {
    if ([operator isEqualToString:PFQueryKeyNotEqualTo]) {
        return [self matchesValue:value notEqualTo:constraint];
    } else if ([operator isEqualToString:PFQueryKeyLessThan]) {
        return [self matchesValue:value lessThan:constraint];
    } else if ([operator isEqualToString:PFQueryKeyLessThanEqualTo]) {
        return [self matchesValue:value lessThanOrEqualTo:constraint];
    } else if ([operator isEqualToString:PFQueryKeyGreaterThan]) {
        return [self matchesValue:value greaterThan:constraint];
    } else if ([operator isEqualToString:PFQueryKeyGreaterThanOrEqualTo]) {
        return [self matchesValue:value greaterThanOrEqualTo:constraint];
    } else if ([operator isEqualToString:PFQueryKeyContainedIn]) {
        return [self matchesValue:value containedIn:constraint];
    } else if ([operator isEqualToString:PFQueryKeyNotContainedIn]) {
        return [self matchesValue:value notContainedIn:constraint];
    } else if ([operator isEqualToString:PFQueryKeyContainsAll]) {
        return [self matchesValue:value containsAllObjectsInArray:constraint];
    } else if ([operator isEqualToString:PFQueryKeyRegex]) {
        return [self matchesValue:value regex:constraint withOptions:allKeyConstraints[PFQueryOptionKeyRegexOptions]];
    } else if ([operator isEqualToString:PFQueryOptionKeyRegexOptions]) {
        // No need to do anything. This is handled by $regex.
        return YES;
    } else if ([operator isEqualToString:PFQueryKeyExists]) {
        return [self matchesValue:value exists:constraint];
    } else if ([operator isEqualToString:PFQueryKeyNearSphere]) {
        return [self matchesValue:value
                       nearSphere:constraint
                      maxDistance:allKeyConstraints[PFQueryOptionKeyMaxDistance]];
    } else if ([operator isEqualToString:PFQueryOptionKeyMaxDistance]) {
        // No need to do anything. This is handled by $nearSphere.
        return YES;
    } else if ([operator isEqualToString:PFQueryKeyWithin]) {
        return [self matchesValue:value within:constraint];
    }
    PFParameterAssertionFailure(@"Local Datastore does not yet support %@ operator.", operator);
    // Shouldn't reach here
    return YES;
}

/**
 Creates a matcher that handles $inQuery constraints.
 */
- (PFConstraintMatcherBlock)createMatcherForKey:(NSString *)key
                                        inQuery:(id)constraints
                                           user:(PFUser *)user {
    PFQuery *query = (PFQuery *)constraints;
    PFSubQueryMatcher *subQueryMatcher = [[PFSubQueryMatcher alloc] initWithSubQuery:query
                                                                        offlineStore:self.offlineStore];
    return [subQueryMatcher createMatcherWithSubQueryMatcherBlock:^BOOL(id object, NSArray *results) {
        id value = [self valueForContainer:object key:key];
        return [[self class] matchesValue:value containedIn:results];
    } user:user];
}

/**
 Creates a matcher that handles $notInQuery constraints.
 */
- (PFConstraintMatcherBlock)createMatcherForKey:(NSString *)key
                                     notInQuery:(id)constraints
                                           user:(PFUser *)user {
    PFConstraintMatcherBlock inQueryMatcher = [self createMatcherForKey:key inQuery:constraints user:user];
    return ^BFTask *(PFObject *object, PFSQLiteDatabase *database) {
        return [inQueryMatcher(object, database) continueWithSuccessBlock:^id(BFTask *task) {
            return @(![task.result boolValue]);
        }];
    };
}

/**
 Creates a matcher that handles $select constraints.
 */
- (PFConstraintMatcherBlock)createMatcherForKey:(NSString *)key
                                         select:(id)constraints
                                           user:(PFUser *)user {
    NSDictionary *constraintDictionary = (NSDictionary *)constraints;
    PFQuery *query = (PFQuery *)constraintDictionary[PFQueryKeyQuery];
    NSString *resultKey = (NSString *)constraintDictionary[PFQueryKeyKey];
    PFSubQueryMatcher *subQueryMatcher = [[PFSubQueryMatcher alloc] initWithSubQuery:query
                                                                        offlineStore:self.offlineStore];
    return [subQueryMatcher createMatcherWithSubQueryMatcherBlock:^BOOL(id object, NSArray *results) {
        id value = [self valueForContainer:object key:key];
        for (id result in results) {
            id resultValue = [self valueForContainer:result key:resultKey];
            if ([[self class] matchesValue:resultValue equalTo:value]) {
                return YES;
            }
        }
        return NO;
    } user:user];
}

/**
 Creates a matcher that handles $dontSelect constraints.
 */
- (PFConstraintMatcherBlock)createMatcherForKey:(NSString *)key
                                     dontSelect:(id)constraints
                                           user:(PFUser *)user {
    PFConstraintMatcherBlock selectMatcher = [self createMatcherForKey:key select:constraints user:user];
    return ^BFTask *(PFObject *object, PFSQLiteDatabase *database) {
        return [selectMatcher(object, database) continueWithSuccessBlock:^id(BFTask *task) {
            return @(![task.result boolValue]);
        }];
    };
}

/**
 Creates a matcher for a particular constraint operator.
 */
- (PFConstraintMatcherBlock)createMatcherWithOperator:(NSString *)operator
                                          constraints:(id)constraint
                                                  key:(NSString *)key
                                    allKeyConstraints:(NSDictionary *)allKeyConstraints
                                                 user:(PFUser *)user {
    if ([operator isEqualToString:PFQueryKeyInQuery]) {
        return [self createMatcherForKey:key inQuery:constraint user:user];
    } else if ([operator isEqualToString:PFQueryKeyNotInQuery]) {
        return [self createMatcherForKey:key notInQuery:constraint user:user];
    } else if ([operator isEqualToString:PFQueryKeySelect]) {
        return [self createMatcherForKey:key select:constraint user:user];
    } else if ([operator isEqualToString:PFQueryKeyDontSelect]) {
        return [self createMatcherForKey:key dontSelect:constraint user:user];
    } else {
        return ^BFTask *(PFObject *object, PFSQLiteDatabase *database) {
            id value = [self valueForContainer:object key:key];
            BOOL matchesValue = [[self class] matchesValue:value
                                                constraint:constraint
                                                  operator:operator
                                         allKeyConstraints:allKeyConstraints];
            return [BFTask taskWithResult:@(matchesValue)];
        };
    }
}

/**
 Handles $or queries.
 */
- (PFConstraintMatcherBlock)createOrMatcherForQueries:(NSArray *)queries user:(PFUser *)user {
    NSMutableArray *matchers = [NSMutableArray array];
    for (PFQuery *query in queries) {
        PFConstraintMatcherBlock matcher = [self createMatcherWithQueryConstraints:query.state.conditions user:user];
        [matchers addObject:matcher];
    }

    // Now OR together the constraints for each query.
    return ^BFTask *(PFObject *object, PFSQLiteDatabase *database) {
        BFTask *task = [BFTask taskWithResult:@NO];
        for (PFConstraintMatcherBlock matcher in matchers) {
            task = [task continueWithSuccessBlock:^id(BFTask *task) {
                if ([task.result boolValue]) {
                    return task;
                }
                return matcher(object, database);
            }];
        }
        return task;
    };
}

/**
 Returns a PFConstraintMatcherBlock that return true iff the object matches queryConstraints. This
 takes in a SQLiteDatabase connection because SQLite is finicky about nesting connections, so we
 want to reuse them whenever possible.
 */
- (PFConstraintMatcherBlock)createMatcherWithQueryConstraints:(NSDictionary *)queryConstraints user:(PFUser *)user {
    NSMutableArray *matchers = [[NSMutableArray alloc] init];
    [queryConstraints enumerateKeysAndObjectsUsingBlock:^(id key, id queryConstraintValue, BOOL *stop) {
        if ([key isEqualToString:PFQueryKeyOr]) {
            // A set of queries to be OR-ed together
            PFConstraintMatcherBlock matcher = [self createOrMatcherForQueries:queryConstraintValue user:user];
            [matchers addObject:matcher];
        } else if ([key isEqualToString:PFQueryKeyRelatedTo]) {
            PFConstraintMatcherBlock matcher = ^BFTask *(PFObject *object, PFSQLiteDatabase *database) {
                PFObject *parent = queryConstraintValue[PFQueryKeyObject];
                NSString *relationKey = queryConstraintValue[PFQueryKeyKey];
                PFRelation *relation = parent[relationKey];

                return [BFTask taskWithResult:@([relation _hasKnownObject:object])];
            };
            [matchers addObject:matcher];
        } else if ([queryConstraintValue isKindOfClass:[NSDictionary class]]) {
            // If it's a set of constraints that should be AND-ed together
            NSDictionary *keyConstraints = (NSDictionary *)queryConstraintValue;
            [keyConstraints enumerateKeysAndObjectsUsingBlock:^(id operator, id keyConstraintValue, BOOL *stop) {
                PFConstraintMatcherBlock matcher = [self createMatcherWithOperator:operator
                                                                       constraints:keyConstraintValue
                                                                               key:key
                                                                 allKeyConstraints:keyConstraints
                                                                              user:user];
                [matchers addObject:matcher];
            }];
        } else {
            // It's not a set of constraints, so it's just a value to compare against.
            PFConstraintMatcherBlock matcher = ^BFTask *(PFObject *object, PFSQLiteDatabase *database) {
                id objectValue = [self valueForContainer:object key:key];
                BOOL matches = [[self class] matchesValue:objectValue equalTo:queryConstraintValue];
                return [BFTask taskWithResult:@(matches)];
            };
            [matchers addObject:matcher];
        }
    }];

    // Now AND together the constraints for each key
    return ^BFTask *(PFObject *object, PFSQLiteDatabase *database) {
        BFTask *task = [BFTask taskWithResult:@YES];
        for (PFConstraintMatcherBlock matcher in matchers) {
            task = [task continueWithSuccessBlock:^id(BFTask *task) {
                if (![task.result boolValue]) {
                    return task;
                }
                @try {
                    return matcher(object, database);
                } @catch (NSException *exception) {
                    // Promote to error to keep the same behavior as online.
                    NSError *error = [PFErrorUtilities errorWithCode:kPFErrorInvalidQuery
                                                             message:exception.reason
                                                           shouldLog:NO];
                    return [BFTask taskWithError:error];
                }
            }];
        }
        return task;
    };
}

///--------------------------------------
#pragma mark - Fetch
///--------------------------------------

- (BFTask *)fetchIncludeAsync:(NSString *)include
                    container:(id)container
                     database:(PFSQLiteDatabase *)database {
    if (container == nil) {
        return [BFTask taskWithResult:nil];
    }

    if ([container isKindOfClass:[NSArray class]]) {
        NSArray *array = (NSArray *)container;
        // We do the fetches in series because it makes it easier to fail on the first error.
        BFTask *task = [BFTask taskWithResult:nil];
        for (id item in array) {
            task = [task continueWithSuccessBlock:^id(BFTask *task) {
                return [self fetchIncludeAsync:include container:item database:database];
            }];
        }
        return task;
    }

    // If we've reached the end of include, then actually do the fetch.
    if (include == nil) {
        if ([container isKindOfClass:[PFObject class]]) {
            PFObject *object = (PFObject *)container;
            return [self.offlineStore fetchObjectLocallyAsync:object database:database];
        } else if (container == [NSNull null]) {
            // Accept NSNull value in included field. We swallow it silently instead of
            // throwing an exception.
            return nil;
        }
        NSError *error = [PFErrorUtilities errorWithCode:kPFErrorInvalidNestedKey
                                                message:@"include is invalid for non-ParseObjects"];
        return [BFTask taskWithError:error];
    }

    // Descend into the container and try again
    NSArray *parts = [include componentsSeparatedByString:@"."];

    NSString *key = parts.firstObject;
    NSString *rest = nil;
    if (parts.count > 1) {
        NSRange range = NSMakeRange(1, parts.count - 1);
        rest = [[parts subarrayWithRange:range] componentsJoinedByString:@"."];
    }

    return [[BFTask taskFromExecutor:[BFExecutor defaultExecutor] withBlock:^id{
        if ([container isKindOfClass:[PFObject class]]) {
            BFTask *fetchTask = [self fetchIncludeAsync:nil container:container database:database];
            return [fetchTask continueWithSuccessBlock:^id(BFTask *task) {
                return ((PFObject *)container)[key];
            }];
        } else if ([container isKindOfClass:[NSDictionary class]]) {
            return ((NSDictionary *)container)[key];
        } else if (container == [NSNull null]) {
            // Accept NSNull value in included field. We swallow it silently instead of
            // throwing an exception.
            return nil;
        }
        NSError *error = [PFErrorUtilities errorWithCode:kPFErrorInvalidNestedKey
                                                 message:@"include is invalid"];
        return [BFTask taskWithError:error];
    }] continueWithSuccessBlock:^id(BFTask *task) {
        return [self fetchIncludeAsync:rest container:task.result database:database];
    }];
}

///--------------------------------------
#pragma mark - User Access
///--------------------------------------

+ (BOOL)userHasReadAccess:(PFUser *)user ofObject:(PFObject *)object {
    if (user == object) {
        return YES;
    }

    PFACL *acl = object.ACL;
    if (acl == nil) {
        return YES;
    }
    if (acl.publicReadAccess) {
        return YES;
    }
    if (user != nil && [acl getReadAccessForUser:user]) {
        return YES;
    }

    // TODO (hallucinogen): Implement roles
    return NO;
}

+ (BOOL)userHasWriteAccess:(PFUser *)user ofObject:(PFObject *)object {
    if (user == object) {
        return YES;
    }

    PFACL *acl = object.ACL;
    if (acl == nil) {
        return YES;
    }
    if (acl.publicWriteAccess) {
        return YES;
    }
    if (user != nil && [acl getWriteAccessForUser:user]) {
        return YES;
    }

    // TODO (hallucinogen): Implement roles
    return NO;
}

///--------------------------------------
#pragma mark - Internal Public Methods
///--------------------------------------

- (PFConstraintMatcherBlock)createMatcherForQueryState:(PFQueryState *)queryState user:(PFUser *)user {
    PFConstraintMatcherBlock constraintMatcher = [self createMatcherWithQueryConstraints:queryState.conditions
                                                                                    user:user];
    // Capture ignoreACLs before the block since it might be modified between matchings.
    BOOL shouldIgnoreACLs = queryState.shouldIgnoreACLs;

    return ^BFTask *(PFObject *object, PFSQLiteDatabase *database) {
        // TODO (hallucinogen): revisit this whether we should check query and object parseClassname equality
        if (!shouldIgnoreACLs && ![[self class] userHasReadAccess:user ofObject:object]) {
            return [BFTask taskWithResult:@NO];
        }
        return constraintMatcher(object, database);
    };
}

///--------------------------------------
#pragma mark - Query Options
///--------------------------------------

- (NSArray *)resultsByApplyingOptions:(PFOfflineQueryOption)options
                         ofQueryState:(PFQueryState *)queryState
                            toResults:(NSArray *)results {
    // No results or empty options.
    if (results.count == 0 || options == 0) {
        return results;
    }

    NSMutableArray *mutableResults = [results mutableCopy];
    if (options & PFOfflineQueryOptionOrder) {
        [self _sortResults:mutableResults ofQueryState:queryState];
    }
    if (options & PFOfflineQueryOptionSkip) {
        NSInteger skip = queryState.skip;
        if (skip > 0) {
            skip = MIN(skip, results.count);
            [mutableResults removeObjectsInRange:NSMakeRange(0, skip)];
        }
    }
    if (options & PFOfflineQueryOptionLimit) {
        NSInteger limit = queryState.limit;
        if (limit >= 0 && mutableResults.count > limit) {
            [mutableResults removeObjectsInRange:NSMakeRange(limit, mutableResults.count - limit)];
        }
    }

    return [mutableResults copy];
}

- (void)_sortResults:(NSMutableArray *)results ofQueryState:(PFQueryState *)queryState {
    NSArray *keys = queryState.sortKeys;
    [keys enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *key = (NSString *)obj;
        if ([key rangeOfString:@"^-?[A-Za-z][A-Za-z0-9_]*$" options:NSRegularExpressionSearch].location == NSNotFound) {
            PFConsistencyAssert([@"_created_at" isEqualToString:key] || [@"_updated_at" isEqualToString:key],
                                @"Invalid key name: %@", key);
        }
    }];

    __block NSString *nearSphereKey = nil;
    __block PFGeoPoint *nearSphereValue = nil;
    [queryState.conditions enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([obj isKindOfClass:[NSDictionary class]]) {
            NSDictionary *keyConstraints = (NSDictionary *)obj;
            if (keyConstraints[PFQueryKeyNearSphere]) {
                nearSphereKey = [key copy];
                nearSphereValue = keyConstraints[PFQueryKeyNearSphere];
            }
        }
    }];

    // If there's nothing to sort based on, then don't do anything.
    if (keys.count == 0 && nearSphereKey == nil) {
        return;
    }

    [results sortUsingComparator:^NSComparisonResult(id lhs, id rhs) {
        if (nearSphereKey != nil) {
            PFGeoPoint *lhsPoint = [self valueForContainer:lhs key:nearSphereKey];
            PFGeoPoint *rhsPoint = [self valueForContainer:rhs key:nearSphereKey];

            double lhsDistance = [lhsPoint distanceInRadiansTo:nearSphereValue];
            double rhsDistance = [rhsPoint distanceInRadiansTo:nearSphereValue];
            if (lhsDistance != rhsDistance) {
                return (lhsDistance - rhsDistance < 0) ? NSOrderedAscending : NSOrderedDescending;
            }
        }

        for (int i = 0; i < keys.count; ++i) {
            NSString *key = keys[i];
            BOOL descending = NO;
            if ([key hasPrefix:@"-"]) {
                descending = YES;
                key = [key substringFromIndex:1];
            }

            id lhsValue = [self valueForContainer:lhs key:key];
            id rhsValue = [self valueForContainer:rhs key:key];

            NSComparisonResult result = NSOrderedSame;
            if (lhsValue != nil && rhsValue == nil) {
                result = NSOrderedAscending;
            } else if (lhsValue == nil && rhsValue != nil) {
                result = NSOrderedDescending;
            } else if (lhsValue == nil && rhsValue == nil) {
                result = NSOrderedSame;
            } else {
                result = [lhsValue compare:rhsValue];
            }

            if (result != 0) {
                return descending ? -result : result;
            }

        }

        return NSOrderedSame;
    }];
}

- (BFTask *)fetchIncludesAsyncForResults:(NSArray *)results
                            ofQueryState:(PFQueryState *)queryState
                              inDatabase:(PFSQLiteDatabase *)database {
    BFTask *fetchTask = [BFTask taskWithResult:nil];
    for (PFObject *object in results) {
        @weakify(self);
        fetchTask = [fetchTask continueWithSuccessBlock:^id(BFTask *task) {
            @strongify(self);
            return [self fetchIncludesForObjectAsync:object
                                          queryState:queryState
                                            database:database];
        }];
    }
    return fetchTask;
}

- (BFTask *)fetchIncludesForObjectAsync:(PFObject *)object
                             queryState:(PFQueryState *)queryState
                               database:(PFSQLiteDatabase *)database {
    NSSet *includes = queryState.includedKeys;
    // We do the fetches in series because it makes it easier to fail on first error.
    BFTask *task = [BFTask taskWithResult:nil];
    for (NSString *include in includes) {
        // We do the fetches in series because it makes it easier to fail on the first error.
        task = [task continueWithSuccessBlock:^id(BFTask *task) {
            return [self fetchIncludeAsync:include container:object database:database];
        }];
    }
    return task;
}

@end
