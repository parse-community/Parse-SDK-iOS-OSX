/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFQuery.h"
#import "PFQueryPrivate.h"

#import <Bolts/BFCancellationTokenSource.h>
#import <Bolts/BFTask.h>

#import "BFTask+Private.h"
#import "PFAssert.h"
#import "PFCommandResult.h"
#import "PFCoreManager.h"
#import "PFCurrentUserController.h"
#import "PFGeoPointPrivate.h"
#import "PFInternalUtils.h"
#import "PFKeyValueCache.h"
#import "PFMutableQueryState.h"
#import "PFObject.h"
#import "PFObjectPrivate.h"
#import "PFOfflineStore.h"
#import "PFPin.h"
#import "PFQueryController.h"
#import "PFQueryUtilities.h"
#import "PFRESTQueryCommand.h"
#import "PFUserPrivate.h"
#import "ParseInternal.h"
#import "Parse_Private.h"

NSString *const PFQueryKeyNotEqualTo = @"$ne";
NSString *const PFQueryKeyLessThan = @"$lt";
NSString *const PFQueryKeyLessThanEqualTo = @"$lte";
NSString *const PFQueryKeyGreaterThan = @"$gt";
NSString *const PFQueryKeyGreaterThanOrEqualTo = @"$gte";
NSString *const PFQueryKeyContainedIn = @"$in";
NSString *const PFQueryKeyNotContainedIn = @"$nin";
NSString *const PFQueryKeyContainsAll = @"$all";
NSString *const PFQueryKeyNearSphere = @"$nearSphere";
NSString *const PFQueryKeyWithin = @"$within";
NSString *const PFQueryKeyRegex = @"$regex";
NSString *const PFQueryKeyExists = @"$exists";
NSString *const PFQueryKeyInQuery = @"$inQuery";
NSString *const PFQueryKeyNotInQuery = @"$notInQuery";
NSString *const PFQueryKeySelect = @"$select";
NSString *const PFQueryKeyDontSelect = @"$dontSelect";
NSString *const PFQueryKeyRelatedTo = @"$relatedTo";
NSString *const PFQueryKeyOr = @"$or";
NSString *const PFQueryKeyQuery = @"query";
NSString *const PFQueryKeyKey = @"key";
NSString *const PFQueryKeyObject = @"object";

NSString *const PFQueryOptionKeyMaxDistance = @"$maxDistance";
NSString *const PFQueryOptionKeyBox = @"$box";
NSString *const PFQueryOptionKeyRegexOptions = @"$options";

/*!
 Checks if an object can be used as value for query equality clauses.
 */
static void PFQueryAssertValidEqualityClauseClass(id object) {
    static NSArray *classes;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        classes = @[ [NSString class], [NSNumber class], [NSDate class], [NSNull class],
                     [PFObject class], [PFGeoPoint class] ];
    });

    for (Class class in classes) {
        if ([object isKindOfClass:class]) {
            return;
        }
    }

    PFParameterAssert(NO, @"Cannot do a comparison query for type: %@", [object class]);
}

/*!
 Checks if an object can be used as value for query ordering clauses.
 */
static void PFQueryAssertValidOrderingClauseClass(id object) {
    static NSArray *classes;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        classes = @[ [NSString class], [NSNumber class], [NSDate class] ];
    });

    for (Class class in classes) {
        if ([object isKindOfClass:class]) {
            return;
        }
    }

    PFParameterAssert(NO, @"Cannot do a query that requires ordering for type: %@", [object class]);
}

@interface PFQuery () {
    BFCancellationTokenSource *_cancellationTokenSource;
}

@property (nonatomic, strong, readwrite) PFMutableQueryState *state;

@end

@implementation PFQuery

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)initWithState:(PFQueryState *)state {
    self = [super init];
    if (!self) return nil;

    _state = [state mutableCopy];

    return self;
}

- (instancetype)initWithClassName:(NSString *)className {
    self = [super init];
    if (!self) return nil;

    _state = [PFMutableQueryState stateWithParseClassName:className];

    return self;
}

///--------------------------------------
#pragma mark - Public Accessors
///--------------------------------------

#pragma mark Basic

- (NSString *)parseClassName {
    return self.state.parseClassName;
}

- (void)setParseClassName:(NSString *)parseClassName {
    [self checkIfCommandIsRunning];
    self.state.parseClassName = parseClassName;
}

#pragma mark Limit

- (void)setLimit:(NSInteger)limit {
    self.state.limit = limit;
}

- (NSInteger)limit {
    return self.state.limit;
}

#pragma mark Skip

- (void)setSkip:(NSInteger)skip {
    self.state.skip = skip;
}

- (NSInteger)skip {
    return self.state.skip;
}

#pragma mark Cache Policy

- (void)setCachePolicy:(PFCachePolicy)cachePolicy {
    [self _checkPinningEnabled:NO];
    [self checkIfCommandIsRunning];

    self.state.cachePolicy = cachePolicy;
}

- (PFCachePolicy)cachePolicy {
    [self _checkPinningEnabled:NO];
    [self checkIfCommandIsRunning];

    return self.state.cachePolicy;
}

#pragma mark Cache Policy

- (void)setMaxCacheAge:(NSTimeInterval)maxCacheAge {
    self.state.maxCacheAge = maxCacheAge;
}

- (NSTimeInterval)maxCacheAge {
    return self.state.maxCacheAge;
}

#pragma mark Trace

- (void)setTrace:(BOOL)trace {
    self.state.trace = trace;
}

- (BOOL)trace {
    return self.state.trace;
}

///--------------------------------------
#pragma mark - Order
///--------------------------------------

- (instancetype)orderByAscending:(NSString *)key {
    [self checkIfCommandIsRunning];
    [self.state sortByKey:key ascending:YES];
    return self;
}

- (instancetype)addAscendingOrder:(NSString *)key {
    [self checkIfCommandIsRunning];
    [self.state addSortKey:key ascending:YES];
    return self;
}

- (instancetype)orderByDescending:(NSString *)key {
    [self checkIfCommandIsRunning];
    [self.state sortByKey:key ascending:NO];
    return self;
}

- (instancetype)addDescendingOrder:(NSString *)key {
    [self checkIfCommandIsRunning];
    [self.state addSortKey:key ascending:NO];
    return self;
}

- (instancetype)orderBySortDescriptor:(NSSortDescriptor *)sortDescriptor {
    NSString *key = sortDescriptor.key;
    if (key) {
        if (sortDescriptor.ascending) {
            [self orderByAscending:key];
        } else {
            [self orderByDescending:key];
        }
    }
    return self;
}

- (instancetype)orderBySortDescriptors:(NSArray *)sortDescriptors {
    [self.state addSortKeysFromSortDescriptors:sortDescriptors];
    return self;
}

///--------------------------------------
#pragma mark - Conditions
///--------------------------------------

// Helper for condition queries.
- (instancetype)whereKey:(NSString *)key condition:(NSString *)condition object:(id)object {
    [self checkIfCommandIsRunning];
    [self.state setConditionType:condition withObject:object forKey:key];
    return self;
}

- (instancetype)whereKey:(NSString *)key equalTo:(id)object {
    [self checkIfCommandIsRunning];
    PFQueryAssertValidEqualityClauseClass(object);
    [self.state setEqualityConditionWithObject:object forKey:key];
    return self;
}

- (instancetype)whereKey:(NSString *)key greaterThan:(id)object {
    PFQueryAssertValidOrderingClauseClass(object);
    return [self whereKey:key condition:PFQueryKeyGreaterThan object:object];
}

- (instancetype)whereKey:(NSString *)key greaterThanOrEqualTo:(id)object {
    PFQueryAssertValidOrderingClauseClass(object);
    return [self whereKey:key condition:PFQueryKeyGreaterThanOrEqualTo object:object];
}

- (instancetype)whereKey:(NSString *)key lessThan:(id)object {
    PFQueryAssertValidOrderingClauseClass(object);
    return [self whereKey:key condition:PFQueryKeyLessThan object:object];
}

- (instancetype)whereKey:(NSString *)key lessThanOrEqualTo:(id)object {
    PFQueryAssertValidOrderingClauseClass(object);
    return [self whereKey:key condition:PFQueryKeyLessThanEqualTo object:object];
}

- (instancetype)whereKey:(NSString *)key notEqualTo:(id)object {
    PFQueryAssertValidEqualityClauseClass(object);
    return [self whereKey:key condition:PFQueryKeyNotEqualTo object:object];
}

- (instancetype)whereKey:(NSString *)key containedIn:(NSArray *)inArray {
    return [self whereKey:key condition:PFQueryKeyContainedIn object:inArray];
}

- (instancetype)whereKey:(NSString *)key notContainedIn:(NSArray *)inArray {
    return [self whereKey:key condition:PFQueryKeyNotContainedIn object:inArray];
}

- (instancetype)whereKey:(NSString *)key containsAllObjectsInArray:(NSArray *)array {
    return [self whereKey:key condition:PFQueryKeyContainsAll object:array];
}

- (instancetype)whereKey:(NSString *)key nearGeoPoint:(PFGeoPoint *)geopoint {
    return [self whereKey:key condition:PFQueryKeyNearSphere object:geopoint];
}

- (instancetype)whereKey:(NSString *)key nearGeoPoint:(PFGeoPoint *)geopoint withinRadians:(double)maxDistance {
    return [[self whereKey:key condition:PFQueryKeyNearSphere object:geopoint]
            whereKey:key condition:PFQueryOptionKeyMaxDistance object:@(maxDistance)];
}

- (instancetype)whereKey:(NSString *)key nearGeoPoint:(PFGeoPoint *)geopoint withinMiles:(double)maxDistance {
    return [self whereKey:key nearGeoPoint:geopoint withinRadians:(maxDistance/EARTH_RADIUS_MILES)];
}

- (instancetype)whereKey:(NSString *)key nearGeoPoint:(PFGeoPoint *)geopoint withinKilometers:(double)maxDistance {
    return [self whereKey:key nearGeoPoint:geopoint withinRadians:(maxDistance/EARTH_RADIUS_KILOMETERS)];
}

- (instancetype)whereKey:(NSString *)key withinGeoBoxFromSouthwest:(PFGeoPoint *)southwest toNortheast:(PFGeoPoint *)northeast {
    NSArray *array = @[ southwest, northeast ];
    NSDictionary *dictionary = @{ PFQueryOptionKeyBox : array };
    return [self whereKey:key condition:PFQueryKeyWithin object:dictionary];
}

- (instancetype)whereKey:(NSString *)key matchesRegex:(NSString *)regex {
    return [self whereKey:key condition:PFQueryKeyRegex object:regex];
}

- (instancetype)whereKey:(NSString *)key matchesRegex:(NSString *)regex modifiers:(NSString *)modifiers {
    [self checkIfCommandIsRunning];
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:2];
    dictionary[PFQueryKeyRegex] = regex;
    if ([modifiers length]) {
        dictionary[PFQueryOptionKeyRegexOptions] = modifiers;
    }
    [self.state setEqualityConditionWithObject:dictionary forKey:key];
    return self;
}

- (instancetype)whereKey:(NSString *)key containsString:(NSString *)substring {
    NSString *regex = [PFQueryUtilities regexStringForString:substring];
    return [self whereKey:key matchesRegex:regex];
}

- (instancetype)whereKey:(NSString *)key hasPrefix:(NSString *)prefix {
    NSString *regex = [NSString stringWithFormat:@"^%@", [PFQueryUtilities regexStringForString:prefix]];
    return [self whereKey:key matchesRegex:regex];
}

- (instancetype)whereKey:(NSString *)key hasSuffix:(NSString *)suffix {
    NSString *regex = [NSString stringWithFormat:@"%@$", [PFQueryUtilities regexStringForString:suffix]];
    return [self whereKey:key matchesRegex:regex];
}

- (instancetype)whereKeyExists:(NSString *)key {
    return [self whereKey:key condition:PFQueryKeyExists object:@YES];
}

- (instancetype)whereKeyDoesNotExist:(NSString *)key {
    return [self whereKey:key condition:PFQueryKeyExists object:@NO];
}

- (instancetype)whereKey:(NSString *)key matchesQuery:(PFQuery *)query {
    return [self whereKey:key condition:PFQueryKeyInQuery object:query];
}

- (instancetype)whereKey:(NSString *)key doesNotMatchQuery:(PFQuery *)query {
    return [self whereKey:key condition:PFQueryKeyNotInQuery object:query];
}

- (instancetype)whereKey:(NSString *)key matchesKey:(NSString *)otherKey inQuery:(PFQuery *)query {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:2];
    dict[PFQueryKeyQuery] = query;
    dict[PFQueryKeyKey] = otherKey;
    return [self whereKey:key condition:PFQueryKeySelect object:dict];
}

- (instancetype)whereKey:(NSString *)key doesNotMatchKey:(NSString *)otherKey inQuery:(PFQuery *)query {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:2];
    dict[PFQueryKeyQuery] = query;
    dict[PFQueryKeyKey] = otherKey;
    return [self whereKey:key condition:PFQueryKeyDontSelect object:dict];
}

- (instancetype)whereRelatedToObject:(PFObject *)parent fromKey:(NSString *)key {
    [self.state setRelationConditionWithObject:parent forKey:key];
    return self;
}

- (void)redirectClassNameForKey:(NSString *)key {
    [self.state redirectClassNameForKey:key];
}

///--------------------------------------
#pragma mark - Include
///--------------------------------------

- (instancetype)includeKey:(NSString *)key {
    [self checkIfCommandIsRunning];
    [self.state includeKey:key];
    return self;
}

///--------------------------------------
#pragma mark - Select
///--------------------------------------

- (instancetype)selectKeys:(NSArray *)keys {
    [self checkIfCommandIsRunning];
    [self.state selectKeys:keys];
    return self;
}

///--------------------------------------
#pragma mark - NSPredicate helper methods
///--------------------------------------

+ (void)assertKeyPathConstant:(NSComparisonPredicate *)predicate {
    PFConsistencyAssert(predicate.leftExpression.expressionType == NSKeyPathExpressionType &&
                        predicate.rightExpression.expressionType == NSConstantValueExpressionType,
                        @"This predicate must have a key path and a constant. %@", predicate);
}

// Adds the conditions from an NSComparisonPredicate to a PFQuery.
- (void)whereComparisonPredicate:(NSComparisonPredicate *)predicate {
    NSExpression *left = predicate.leftExpression;
    NSExpression *right = predicate.rightExpression;

    switch (predicate.predicateOperatorType) {
        case NSEqualToPredicateOperatorType: {
            [[self class] assertKeyPathConstant:predicate];
            [self whereKey:left.keyPath equalTo:(right.constantValue ?: [NSNull null])];
            return;
        }
        case NSNotEqualToPredicateOperatorType: {
            [[self class] assertKeyPathConstant:predicate];
            [self whereKey:left.keyPath notEqualTo:(right.constantValue ?: [NSNull null])];
            return;
        }
        case NSLessThanPredicateOperatorType: {
            [[self class] assertKeyPathConstant:predicate];
            [self whereKey:left.keyPath lessThan:right.constantValue];
            return;
        }
        case NSLessThanOrEqualToPredicateOperatorType: {
            [[self class] assertKeyPathConstant:predicate];
            [self whereKey:left.keyPath lessThanOrEqualTo:right.constantValue];
            return;
        }
        case NSGreaterThanPredicateOperatorType: {
            [[self class] assertKeyPathConstant:predicate];
            [self whereKey:left.keyPath greaterThan:right.constantValue];
            return;
        }
        case NSGreaterThanOrEqualToPredicateOperatorType: {
            [[self class] assertKeyPathConstant:predicate];
            [self whereKey:left.keyPath greaterThanOrEqualTo:right.constantValue];
            return;
        }
        case NSInPredicateOperatorType: {
            if (left.expressionType == NSKeyPathExpressionType &&
                right.expressionType == NSConstantValueExpressionType) {
                if ([right.constantValue isKindOfClass:[PFQuery class]]) {
                    // Like "value IN subquery
                    [self whereKey:left.keyPath matchesQuery:right.constantValue];
                } else {
                    // Like "value IN %@", @{@1, @2, @3, @4}
                    [self whereKey:left.keyPath containedIn:right.constantValue];
                }
            } else if (left.expressionType == NSKeyPathExpressionType &&
                       right.expressionType == NSAggregateExpressionType &&
                       [right.constantValue isKindOfClass:[NSArray class]]) {
                // Like "value IN {1, 2, 3, 4}"
                NSArray *constants = right.constantValue;
                NSMutableArray *values = [NSMutableArray arrayWithCapacity:constants.count];
                for (NSExpression *expression in constants) {
                    [values addObject:expression.constantValue];
                }
                [self whereKey:left.keyPath containedIn:values];
            } else if (right.expressionType == NSEvaluatedObjectExpressionType &&
                       left.expressionType == NSKeyPathExpressionType) {
                // Like "value IN SELF"
                [self whereKeyExists:left.keyPath];
            } else {
                [NSException raise:NSInternalInconsistencyException
                            format:@"An IN predicate must have a key path and a constant."];
            }
            return;
        }
        case NSCustomSelectorPredicateOperatorType: {
            if (predicate.customSelector != NSSelectorFromString(@"notContainedIn:")) {
                [NSException raise:NSInternalInconsistencyException
                            format:@"Predicates with custom selectors are not supported."];
            }

            if (right.expressionType == NSConstantValueExpressionType &&
                left.expressionType == NSKeyPathExpressionType) {
                if ([right.constantValue isKindOfClass:[PFQuery class]]) {
                    // Like "NOT (value IN subquery)"
                    [self whereKey:left.keyPath doesNotMatchQuery:right.constantValue];
                } else {
                    // Like "NOT (value in %@)", @{@1, @2, @3}
                    [self whereKey:left.keyPath notContainedIn:right.constantValue];
                }
            } else if (left.expressionType == NSKeyPathExpressionType &&
                       right.expressionType == NSAggregateExpressionType &&
                       [right.constantValue isKindOfClass:[NSArray class]]) {
                // Like "NOT (value IN {1, 2, 3, 4})"
                NSArray *constants = right.constantValue;
                NSMutableArray *values = [NSMutableArray arrayWithCapacity:constants.count];
                for (NSExpression *expression in constants) {
                    [values addObject:expression.constantValue];
                }
                [self whereKey:left.keyPath notContainedIn:values];
            } else if (right.expressionType == NSEvaluatedObjectExpressionType &&
                       left.expressionType == NSKeyPathExpressionType) {
                // Like "NOT (value IN SELF)"
                [self whereKeyDoesNotExist:left.keyPath];
            } else {
                [NSException raise:NSInternalInconsistencyException
                            format:@"A NOT IN predicate must have a key path and a constant array."];
            }
            return;
        }
        case NSBeginsWithPredicateOperatorType: {
            [[self class] assertKeyPathConstant:predicate];
            [self whereKey:left.keyPath hasPrefix:right.constantValue];
            return;
        }
        case NSContainsPredicateOperatorType: {
            [NSException raise:NSInternalInconsistencyException
                        format:@"Regex queries are not supported with "
             "[PFQuery queryWithClassName:predicate:]. Please try to structure your "
             "data so that you can use an equalTo or containedIn query."];
        }
        case NSEndsWithPredicateOperatorType: {
            [NSException raise:NSInternalInconsistencyException
                        format:@"Regex queries are not supported with "
             "[PFQuery queryWithClassName:predicate:]. Please try to structure your "
             "data so that you can use an equalTo or containedIn query."];
        }
        case NSMatchesPredicateOperatorType: {
            [NSException raise:NSInternalInconsistencyException
                        format:@"Regex queries are not supported with "
             "[PFQuery queryWithClassName:predicate:]. Please try to structure your "
             "data so that you can use an equalTo or containedIn query."];
        }
        case NSLikePredicateOperatorType: {
            [NSException raise:NSInternalInconsistencyException
                        format:@"LIKE is not supported by PFQuery."];
        }
        case NSBetweenPredicateOperatorType:
        default: {
            [NSException raise:NSInternalInconsistencyException
                        format:@"This comparison predicate is not supported. (%zd)", predicate.predicateOperatorType];
        }
    }
}

/*!
 Creates a PFQuery with the constraints given by predicate.
 This method assumes the predicate has already been normalized.
 */
+ (instancetype)queryWithClassName:(NSString *)className normalizedPredicate:(NSPredicate *)predicate {
    if ([predicate isKindOfClass:[NSComparisonPredicate class]]) {
        PFQuery *query = [self queryWithClassName:className];
        [query whereComparisonPredicate:(NSComparisonPredicate *)predicate];
        return query;
    } else if ([predicate isKindOfClass:[NSCompoundPredicate class]]) {
        NSCompoundPredicate *compound = (NSCompoundPredicate *)predicate;
        switch (compound.compoundPredicateType) {
            case NSAndPredicateType: {
                PFQuery *query = nil;
                NSMutableArray *subpredicates = [NSMutableArray array];
                // If there's an OR query in here, we'll start with it.
                for (NSPredicate *subpredicate in compound.subpredicates) {
                    if ([subpredicate isKindOfClass:[NSCompoundPredicate class]] &&
                        ((NSCompoundPredicate *)subpredicate).compoundPredicateType == NSOrPredicateType) {
                        if (query) {
                            [NSException raise:NSInternalInconsistencyException
                                        format:@"A query had 2 ORs in an AND after normalization. %@",
                             predicate];
                        }
                        query = [self queryWithClassName:className normalizedPredicate:subpredicate];
                    } else {
                        [subpredicates addObject:subpredicate];
                    }
                }
                // If there was no OR query, then start with an empty query.
                if (!query) {
                    query = [self queryWithClassName:className];
                }
                for (NSPredicate *subpredicate in subpredicates) {
                    if (![subpredicate isKindOfClass:[NSComparisonPredicate class]]) {
                        // This should never happen.
                        [NSException raise:NSInternalInconsistencyException
                                    format:@"A predicate had a non-comparison predicate inside an AND "
                         "after normalization. %@", predicate];
                    }
                    NSComparisonPredicate *comparison = (NSComparisonPredicate *)subpredicate;
                    [query whereComparisonPredicate:comparison];
                }
                return query;
            }
            case NSOrPredicateType: {
                NSMutableArray *subqueries = [NSMutableArray arrayWithCapacity:compound.subpredicates.count];
                if (compound.subpredicates.count > 4) {
                    [NSException raise:NSInternalInconsistencyException
                                format:@"This query is too complex. It had an OR with >4 subpredicates "
                     "after normalization."];
                }
                for (NSPredicate *subpredicate in compound.subpredicates) {
                    [subqueries addObject:[self queryWithClassName:className normalizedPredicate:subpredicate]];
                }
                return [self orQueryWithSubqueries:subqueries];
            }
            case NSNotPredicateType:
            default: {
                // This should never happen.
                [NSException raise:NSInternalInconsistencyException
                            format:@"A predicate had a NOT after normalization. %@", predicate];
                return nil;
            }
        }
    } else {
        [NSException raise:NSInternalInconsistencyException format:@"Unknown predicate type."];
        return nil;
    }
}

///--------------------------------------
#pragma mark - Helpers
///--------------------------------------

- (void)checkIfCommandIsRunning {
    @synchronized (self) {
        if (_cancellationTokenSource) {
            [NSException raise:NSInternalInconsistencyException
                        format:@"This query has an outstanding network connection. You have to wait until it's done."];
        }
    }
}

- (void)markAsRunning:(BFCancellationTokenSource *)source {
    [self checkIfCommandIsRunning];
    @synchronized (self) {
        _cancellationTokenSource = source;
    }
}

///--------------------------------------
#pragma mark - Constructors
///--------------------------------------

+ (instancetype)queryWithClassName:(NSString *)className {
    return [[self alloc] initWithClassName:className];
}

+ (instancetype)queryWithClassName:(NSString *)className predicate:(NSPredicate *)predicate {
    if (!predicate) {
        return [self queryWithClassName:className];
    }

    NSPredicate *normalizedPredicate = [PFQueryUtilities predicateByNormalizingPredicate:predicate];
    return [self queryWithClassName:className normalizedPredicate:normalizedPredicate];
}

+ (instancetype)orQueryWithSubqueries:(NSArray *)queries {
    NSMutableArray *array = [NSMutableArray array];
    NSString *className = nil;
    for (id object in queries) {
        PFParameterAssert([object isKindOfClass:[PFQuery class]],
                          @"All elements should be instances of `PFQuery` class.");

        PFQuery *query = (PFQuery *)object;
        if (!className) {
            className = query.parseClassName;
        } else {
            PFParameterAssert([query.parseClassName isEqualToString:className],
                              @"All sub queries of an `or` query should be on the same class.");
        }

        [array addObject:query];
    }
    PFQuery *query = [self queryWithClassName:className];
    [query.state setEqualityConditionWithObject:array forKey:PFQueryKeyOr];
    return query;
}

///--------------------------------------
#pragma mark - Get with objectId
///--------------------------------------

+ (PFObject *)getObjectOfClass:(NSString *)objectClass objectId:(NSString *)objectId {
    return [self getObjectOfClass:objectClass objectId:objectId error:nil];
}

+ (PFObject *)getObjectOfClass:(NSString *)objectClass
                      objectId:(NSString *)objectId
                         error:(NSError **)error {
    PFQuery *query = [self queryWithClassName:objectClass];
    return [query getObjectWithId:objectId error:error];
}

// TODO (hallucinogen): we may want to remove this in 2.0 since we can just use the static counterpart
- (PFObject *)getObjectWithId:(NSString *)objectId {
    return [self getObjectWithId:objectId error:nil];
}

- (PFObject *)getObjectWithId:(NSString *)objectId error:(NSError **)error {
    return [[self getObjectInBackgroundWithId:objectId] waitForResult:error];
}

- (BFTask *)getObjectInBackgroundWithId:(NSString *)objectId {
    if ([objectId length] == 0) {
        return [BFTask taskWithResult:nil];
    }

    PFConsistencyAssert(self.state.cachePolicy != kPFCachePolicyCacheThenNetwork,
                        @"kPFCachePolicyCacheThenNetwork can only be used with methods that have a callback.");
    return [self _getObjectWithIdAsync:objectId cachePolicy:self.state.cachePolicy after:nil];
}

- (void)getObjectInBackgroundWithId:(NSString *)objectId block:(PFObjectResultBlock)block {
    @synchronized (self) {
        if (!self.state.queriesLocalDatastore && self.state.cachePolicy == kPFCachePolicyCacheThenNetwork) {
            BFTask *cacheTask = [[self _getObjectWithIdAsync:objectId
                                                 cachePolicy:kPFCachePolicyCacheOnly
                                                       after:nil] thenCallBackOnMainThreadAsync:block];
            [[self _getObjectWithIdAsync:objectId
                             cachePolicy:kPFCachePolicyNetworkOnly
                                   after:cacheTask] thenCallBackOnMainThreadAsync:block];
        } else {
            [[self getObjectInBackgroundWithId:objectId] thenCallBackOnMainThreadAsync:block];
        }
    }
}

- (void)getObjectInBackgroundWithId:(NSString *)objectId target:(id)target selector:(SEL)selector {
    [self getObjectInBackgroundWithId:objectId block:^(PFObject *object, NSError *error) {
        [PFInternalUtils safePerformSelector:selector withTarget:target object:object object:error];
    }];
}

- (BFTask *)_getObjectWithIdAsync:(NSString *)objectId cachePolicy:(PFCachePolicy)cachePolicy after:(BFTask *)task {
    self.limit = 1;
    self.skip = 0;
    [self.state removeAllConditions];
    [self.state setEqualityConditionWithObject:objectId forKey:@"objectId"];

    PFQueryState *state = [self _queryStateCopyWithCachePolicy:cachePolicy];
    return [[self _findObjectsAsyncForQueryState:state
                                           after:task] continueWithSuccessBlock:^id(BFTask *task) {
        NSArray *objects = task.result;
        if (objects.count == 0) {
            return [BFTask taskWithError:[PFQueryUtilities objectNotFoundError]];
        }

        return [BFTask taskWithResult:objects.lastObject];
    }];
}

///--------------------------------------
#pragma mark - Get Users (Deprecated)
///--------------------------------------

+ (PFUser *)getUserObjectWithId:(NSString *)objectId {
    return [self getUserObjectWithId:objectId error:nil];
}

+ (PFUser *)getUserObjectWithId:(NSString *)objectId error:(NSError **)error {
    PFQuery *query = [PFUser query];
    PFUser *object = (PFUser *)[query getObjectWithId:objectId error:error];

    return object;
}

+ (instancetype)queryForUser {
    return [PFUser query];
}

///--------------------------------------
#pragma mark - Find Objects
///--------------------------------------

- (NSArray *)findObjects {
    return [self findObjects:nil];
}

- (NSArray *)findObjects:(NSError **)error {
    return [[self findObjectsInBackground] waitForResult:error];
}

- (BFTask *)findObjectsInBackground {
    PFQueryState *state = [self _queryStateCopy];

    PFConsistencyAssert(state.cachePolicy != kPFCachePolicyCacheThenNetwork,
                        @"kPFCachePolicyCacheThenNetwork can only be used with methods that have a callback.");
    return [self _findObjectsAsyncForQueryState:state after:nil];
}

- (void)findObjectsInBackgroundWithBlock:(PFQueryArrayResultBlock)block {
    @synchronized (self) {
        if (!self.state.queriesLocalDatastore && self.state.cachePolicy == kPFCachePolicyCacheThenNetwork) {
            PFQueryState *cacheQueryState = [self _queryStateCopyWithCachePolicy:kPFCachePolicyCacheOnly];
            BFTask *cacheTask = [[self _findObjectsAsyncForQueryState:cacheQueryState
                                                                after:nil] thenCallBackOnMainThreadAsync:block];

            PFQueryState *remoteQueryState = [self _queryStateCopyWithCachePolicy:kPFCachePolicyNetworkOnly];
            [[self _findObjectsAsyncForQueryState:remoteQueryState
                                            after:cacheTask] thenCallBackOnMainThreadAsync:block];
        } else {
            [[self findObjectsInBackground] thenCallBackOnMainThreadAsync:block];
        }
    }
}

- (void)findObjectsInBackgroundWithTarget:(id)target selector:(SEL)selector {
    [self findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        [PFInternalUtils safePerformSelector:selector withTarget:target object:objects object:error];
    }];
}

- (BFTask *)_findObjectsAsyncForQueryState:(PFQueryState *)queryState after:(BFTask *)previous {
    BFCancellationTokenSource *cancellationTokenSource = _cancellationTokenSource;
    if (!previous) {
        cancellationTokenSource = [BFCancellationTokenSource cancellationTokenSource];
        [self markAsRunning:cancellationTokenSource];
    }

    BFTask *start = (previous ?: [BFTask taskWithResult:nil]);

    [self _validateQueryState];
    @weakify(self);
    return [[[start continueWithBlock:^id(BFTask *task) {
        @strongify(self);
        return [[self class] _getCurrentUserForQueryState:queryState];
    }] continueWithBlock:^id(BFTask *task) {
        @strongify(self);
        PFUser *user = task.result;
        return [[[self class] queryController] findObjectsAsyncForQueryState:queryState
                                                       withCancellationToken:cancellationTokenSource.token
                                                                        user:user];
    }] continueWithBlock:^id(BFTask *task) {
        @strongify(self);
        if (!self) {
            return task;
        }
        @synchronized (self) {
            if (_cancellationTokenSource == cancellationTokenSource) {
                _cancellationTokenSource = nil;
            }
        }
        return task;
    }];
}

///--------------------------------------
#pragma mark - Get Object
///--------------------------------------

- (PFObject *)getFirstObject {
    return [self getFirstObject:nil];
}

- (PFObject *)getFirstObject:(NSError **)error {
    return [[self getFirstObjectInBackground] waitForResult:error];
}

- (BFTask *)getFirstObjectInBackground {
    PFConsistencyAssert(self.state.cachePolicy != kPFCachePolicyCacheThenNetwork,
                        @"kPFCachePolicyCacheThenNetwork can only be used with methods that have a callback.");
    return [self _getFirstObjectAsyncWithCachePolicy:self.state.cachePolicy after:nil];
}

- (void)getFirstObjectInBackgroundWithBlock:(PFObjectResultBlock)block {
    @synchronized (self) {
        if (!self.state.queriesLocalDatastore && self.state.cachePolicy == kPFCachePolicyCacheThenNetwork) {
            BFTask *cacheTask = [[self _getFirstObjectAsyncWithCachePolicy:kPFCachePolicyCacheOnly
                                                                     after:nil] thenCallBackOnMainThreadAsync:block];
            [[self _getFirstObjectAsyncWithCachePolicy:kPFCachePolicyNetworkOnly
                                                 after:cacheTask] thenCallBackOnMainThreadAsync:block];
        } else {
            [[self getFirstObjectInBackground] thenCallBackOnMainThreadAsync:block];
        }
    }
}

- (void)getFirstObjectInBackgroundWithTarget:(id)target selector:(SEL)selector {
    [self getFirstObjectInBackgroundWithBlock:^(PFObject *result, NSError *error) {
        [PFInternalUtils safePerformSelector:selector withTarget:target object:result object:error];
    }];
}

- (BFTask *)_getFirstObjectAsyncWithCachePolicy:(PFCachePolicy)cachePolicy after:(BFTask *)task {
    self.limit = 1;

    PFQueryState *state = [self _queryStateCopyWithCachePolicy:cachePolicy];
    return [[self _findObjectsAsyncForQueryState:state after:task] continueWithSuccessBlock:^id(BFTask *task) {
        NSArray *objects = task.result;
        if (objects.count == 0) {
            return [BFTask taskWithError:[PFQueryUtilities objectNotFoundError]];
        }

        return [BFTask taskWithResult:objects.lastObject];
    }];
}

///--------------------------------------
#pragma mark - Count Objects
///--------------------------------------

- (NSInteger)countObjects {
    return [self countObjects:nil];
}

- (NSInteger)countObjects:(NSError **)error {
    NSNumber *count = [[self countObjectsInBackground] waitForResult:error];
    if (!count) {
        // TODO: (nlutsenko) It's really weird that we are inconsistent in sync vs async methods.
        // Leaving for now since some devs might be relying on this.
        return -1;
    }

    return [count integerValue];
}

- (BFTask *)countObjectsInBackground {
    PFConsistencyAssert(self.state.cachePolicy != kPFCachePolicyCacheThenNetwork,
                        @"kPFCachePolicyCacheThenNetwork can only be used with methods that have a callback.");
    return [self _countObjectsAsyncForQueryState:[self _queryStateCopy] after:nil];
}

- (void)countObjectsInBackgroundWithTarget:(id)target selector:(SEL)selector {
    [self countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
        [PFInternalUtils safePerformSelector:selector withTarget:target object:@(number) object:error];
    }];
}

- (void)countObjectsInBackgroundWithBlock:(PFIntegerResultBlock)block {
    PFIdResultBlock callback = nil;
    if (block) {
        callback = ^(id result, NSError *error) {
            block([result intValue], error);
        };
    }

    @synchronized (self) {
        if (!self.state.queriesLocalDatastore && self.state.cachePolicy == kPFCachePolicyCacheThenNetwork) {
            PFQueryState *cacheQueryState = [self _queryStateCopyWithCachePolicy:kPFCachePolicyCacheOnly];
            BFTask *cacheTask = [[self _countObjectsAsyncForQueryState:cacheQueryState
                                                                 after:nil] thenCallBackOnMainThreadAsync:callback];

            PFQueryState *remoteQueryState = [self _queryStateCopyWithCachePolicy:kPFCachePolicyNetworkOnly];
            [[self _countObjectsAsyncForQueryState:remoteQueryState
                                             after:cacheTask] thenCallBackOnMainThreadAsync:callback];
        } else {
            [[self countObjectsInBackground] thenCallBackOnMainThreadAsync:callback];
        }
    }
}

- (BFTask *)_countObjectsAsyncForQueryState:(PFQueryState *)queryState after:(BFTask *)previousTask {
    BFCancellationTokenSource *cancellationTokenSource = _cancellationTokenSource;
    if (!previousTask) {
        cancellationTokenSource = [BFCancellationTokenSource cancellationTokenSource];
        [self markAsRunning:cancellationTokenSource];
    }

    BFTask *start = (previousTask ?: [BFTask taskWithResult:nil]);

    [self _validateQueryState];
    @weakify(self);
    return [[[start continueWithBlock:^id(BFTask *task) {
        return [[self class] _getCurrentUserForQueryState:queryState];
    }] continueWithBlock:^id(BFTask *task) {
        @strongify(self);
        PFUser *user = task.result;
        return [[[self class] queryController] countObjectsAsyncForQueryState:queryState
                                                        withCancellationToken:cancellationTokenSource.token
                                                                         user:user];
    }] continueWithBlock:^id(BFTask *task) {
        @synchronized(self) {
            if (_cancellationTokenSource == cancellationTokenSource) {
                _cancellationTokenSource = nil;
            }
        }
        return task;
    }];
}

///--------------------------------------
#pragma mark - Cancel
///--------------------------------------

- (void)cancel {
    @synchronized (self) {
        if (_cancellationTokenSource) {
            [_cancellationTokenSource cancel];
            _cancellationTokenSource = nil;
        }
    }
}

///--------------------------------------
#pragma mark - NSCopying
///--------------------------------------

- (instancetype)copyWithZone:(NSZone *)zone {
    return [[[self class] allocWithZone:zone] initWithState:self.state];
}

///--------------------------------------
#pragma mark NSObject
///--------------------------------------

- (NSUInteger)hash {
    return [self.state hash];
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }

    if (![object isKindOfClass:[PFQuery class]]) {
        return NO;
    }

    return [self.state isEqual:((PFQuery *)object).state];
}

///--------------------------------------
#pragma mark - Caching
///--------------------------------------

- (BOOL)hasCachedResult {
    return [[[self class] queryController] hasCachedResultForQueryState:self.state
                                                           sessionToken:[PFUser currentSessionToken]];
}

- (void)clearCachedResult {
    [[[self class] queryController] clearCachedResultForQueryState:self.state
                                                      sessionToken:[PFUser currentSessionToken]];
}

+ (void)clearAllCachedResults {
    [[self queryController] clearAllCachedResults];
}

///--------------------------------------
#pragma mark - Check Pinning Status
///--------------------------------------

/*!
 If `enabled` is YES, raise an exception if OfflineStore is not enabled. If `enabled` is NO, raise
 an exception if OfflineStore is enabled.
 */
- (void)_checkPinningEnabled:(BOOL)enabled {
    BOOL loaded = [Parse _currentManager].offlineStoreLoaded;
    if (enabled) {
        PFConsistencyAssert(loaded, @"Method requires Pinning enabled.");
    } else {
        PFConsistencyAssert(!loaded, @"Method not allowed when Pinning is enabled.");
    }
}

///--------------------------------------
#pragma mark - Query Source
///--------------------------------------

- (instancetype)fromLocalDatastore {
    return [self fromPinWithName:nil];
}

- (instancetype)fromPin {
    return [self fromPinWithName:PFObjectDefaultPin];
}

- (instancetype)fromPinWithName:(NSString *)name {
    [self _checkPinningEnabled:YES];
    [self checkIfCommandIsRunning];

    self.state.queriesLocalDatastore = YES;
    self.state.localDatastorePinName = [name copy];

    return self;
}

- (instancetype)ignoreACLs {
    [self _checkPinningEnabled:YES];
    [self checkIfCommandIsRunning];

    self.state.shouldIgnoreACLs = YES;

    return self;
}

///--------------------------------------
#pragma mark - Query State
///--------------------------------------

- (PFQueryState *)_queryStateCopy {
    return [self.state copy];
}

- (PFQueryState *)_queryStateCopyWithCachePolicy:(PFCachePolicy)cachePolicy {
    PFMutableQueryState *state = [self.state mutableCopy];
    state.cachePolicy = cachePolicy;
    return state;
}

- (void)_validateQueryState {
    PFConsistencyAssert(self.state.queriesLocalDatastore || !self.state.shouldIgnoreACLs,
                        @"`ignoreACLs` can only be used with Local Datastore queries.");
}

///--------------------------------------
#pragma mark - Query Controller
///--------------------------------------

+ (PFQueryController *)queryController {
    return [Parse _currentManager].coreManager.queryController;
}

///--------------------------------------
#pragma mark - User
///--------------------------------------

+ (BFTask *)_getCurrentUserForQueryState:(PFQueryState *)state {
    if (state.shouldIgnoreACLs) {
        return [BFTask taskWithResult:nil];
    }
    return [[Parse _currentManager].coreManager.currentUserController getCurrentObjectAsync];
}

@end
