/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFRESTQueryCommand.h"

#import "PFAssert.h"
#import "PFEncoder.h"
#import "PFHTTPRequest.h"
#import "PFQueryPrivate.h"
#import "PFQueryState.h"

@implementation PFRESTQueryCommand

///--------------------------------------
#pragma mark - Find
///--------------------------------------

+ (instancetype)findCommandForQueryState:(PFQueryState *)queryState withSessionToken:(NSString *)sessionToken {
    NSDictionary *parameters = [self findCommandParametersForQueryState:queryState];
    return [self _findCommandForClassWithName:queryState.parseClassName
                                   parameters:parameters
                                 sessionToken:sessionToken];
}

+ (instancetype)findCommandForClassWithName:(NSString *)className
                                      order:(NSString *)order
                                 conditions:(NSDictionary *)conditions
                               selectedKeys:(NSSet *)selectedKeys
                               includedKeys:(NSSet *)includedKeys
                                      limit:(NSInteger)limit
                                       skip:(NSInteger)skip
                               extraOptions:(NSDictionary *)extraOptions
                             tracingEnabled:(BOOL)trace
                               sessionToken:(NSString *)sessionToken {
    NSDictionary *parameters = [self findCommandParametersWithOrder:order
                                                         conditions:conditions
                                                       selectedKeys:selectedKeys
                                                       includedKeys:includedKeys
                                                              limit:limit
                                                               skip:skip
                                                       extraOptions:extraOptions
                                                     tracingEnabled:trace];
    return [self _findCommandForClassWithName:className
                                   parameters:parameters
                                 sessionToken:sessionToken];
}

+ (instancetype)_findCommandForClassWithName:(NSString *)className
                                  parameters:(NSDictionary *)parameters
                                sessionToken:(NSString *)sessionToken {
    NSString *httpPath = [NSString stringWithFormat:@"classes/%@", className];
    PFRESTQueryCommand *command = [self commandWithHTTPPath:httpPath
                                                 httpMethod:PFHTTPRequestMethodGET
                                                 parameters:parameters
                                               sessionToken:sessionToken];
    return command;
}

///--------------------------------------
#pragma mark - Count
///--------------------------------------

+ (instancetype)countCommandFromFindCommand:(PFRESTQueryCommand *)findCommand {
    NSMutableDictionary *parameters = [findCommand.parameters mutableCopy];
    parameters[@"count"] = @"1";
    parameters[@"limit"] = @"0"; // Set the limit to 0, as we are not interested in results at all.
    [parameters removeObjectForKey:@"skip"];

    return [self commandWithHTTPPath:findCommand.httpPath
                          httpMethod:findCommand.httpMethod
                          parameters:[parameters copy]
                        sessionToken:findCommand.sessionToken];
}

///--------------------------------------
#pragma mark - Parameters
///--------------------------------------

+ (NSDictionary *)findCommandParametersForQueryState:(PFQueryState *)queryState {
    return [self findCommandParametersWithOrder:queryState.sortOrderString
                                     conditions:queryState.conditions
                                   selectedKeys:queryState.selectedKeys
                                   includedKeys:queryState.includedKeys
                                          limit:queryState.limit
                                           skip:queryState.skip
                                   extraOptions:queryState.extraOptions
                                 tracingEnabled:queryState.trace];
}

+ (NSDictionary *)findCommandParametersWithOrder:(NSString *)order
                                      conditions:(NSDictionary *)conditions
                                    selectedKeys:(NSSet *)selectedKeys
                                    includedKeys:(NSSet *)includedKeys
                                           limit:(NSInteger)limit
                                            skip:(NSInteger)skip
                                    extraOptions:(NSDictionary *)extraOptions
                                  tracingEnabled:(BOOL)trace {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];

    if (order.length) {
        parameters[@"order"] = order;
    }
    if (selectedKeys) {
        NSArray *sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES selector:@selector(compare:)] ];
        NSArray *keysArray = [selectedKeys sortedArrayUsingDescriptors:sortDescriptors];
        parameters[@"keys"] = [keysArray componentsJoinedByString:@","];
    }
    if (includedKeys.count > 0) {
        NSArray *sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES selector:@selector(compare:)] ];
        NSArray *keysArray = [includedKeys sortedArrayUsingDescriptors:sortDescriptors];
        parameters[@"include"] = [keysArray componentsJoinedByString:@","];
    }
    if (limit >= 0) {
        parameters[@"limit"] = [NSString stringWithFormat:@"%d", (int)limit];
    }
    if (skip > 0) {
        parameters[@"skip"] = [NSString stringWithFormat:@"%d", (int)skip];
    }
    if (trace) {
        // TODO: (nlutsenko) Double check that tracing still works. Maybe create test for it.
        parameters[@"trace"] = @"1";
    }
    [extraOptions enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        parameters[key] = obj;
    }];

    if (conditions.count > 0) {
        NSMutableDictionary *whereData = [[NSMutableDictionary alloc] init];
        [conditions enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            if ([key isEqualToString:@"$or"]) {
                NSArray *array = (NSArray *)obj;
                NSMutableArray *newArray = [NSMutableArray array];
                for (PFQuery *subquery in array) {
                    // TODO: (nlutsenko) Move this validation into PFQuery/PFQueryState.
                    PFParameterAssert(subquery.state.limit < 0, @"OR queries do not support sub queries with limits");
                    PFParameterAssert(subquery.state.skip == 0, @"OR queries do not support sub queries with skip");
                    PFParameterAssert(subquery.state.sortKeys.count == 0, @"OR queries do not support sub queries with order");
                    PFParameterAssert(subquery.state.includedKeys.count == 0, @"OR queries do not support sub-queries with includes");
                    PFParameterAssert(subquery.state.selectedKeys == nil, @"OR queries do not support sub-queries with selectKeys");

                    NSDictionary *queryDict = [self findCommandParametersWithOrder:subquery.state.sortOrderString
                                                                        conditions:subquery.state.conditions
                                                                      selectedKeys:subquery.state.selectedKeys
                                                                      includedKeys:subquery.state.includedKeys
                                                                             limit:subquery.state.limit
                                                                              skip:subquery.state.skip
                                                                      extraOptions:nil
                                                                    tracingEnabled:NO];

                    queryDict = queryDict[@"where"];
                    if (queryDict.count > 0) {
                        [newArray addObject:queryDict];
                    } else {
                        [newArray addObject:@{}];
                    }
                }
                whereData[key] = newArray;
            } else {
                id object = [self _encodeSubqueryIfNeeded:obj];
                whereData[key] = [[PFPointerObjectEncoder objectEncoder] encodeObject:object];
            }
        }];

        parameters[@"where"] = whereData;
    }

    return parameters;
}

+ (id)_encodeSubqueryIfNeeded:(id)object {
    if (![object isKindOfClass:[NSDictionary class]]) {
        return object;
    }

    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithCapacity:[object count]];
    [object enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([obj isKindOfClass:[PFQuery class]]) {
            PFQuery *subquery = (PFQuery *)obj;
            NSMutableDictionary *subqueryParameters = [[self findCommandParametersWithOrder:subquery.state.sortOrderString
                                                                                 conditions:subquery.state.conditions
                                                                               selectedKeys:subquery.state.selectedKeys
                                                                               includedKeys:subquery.state.includedKeys
                                                                                      limit:subquery.state.limit
                                                                                       skip:subquery.state.skip
                                                                               extraOptions:subquery.state.extraOptions
                                                                             tracingEnabled:NO] mutableCopy];
            subqueryParameters[@"className"] = subquery.parseClassName;
            obj = subqueryParameters;
        } else if ([obj isKindOfClass:[NSDictionary class]]) {
            obj = [self _encodeSubqueryIfNeeded:obj];
        }

        parameters[key] = obj;
    }];
    return parameters;
}

@end
