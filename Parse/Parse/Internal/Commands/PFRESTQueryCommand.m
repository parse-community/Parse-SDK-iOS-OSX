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
#import "PFQueryConstants.h"

@implementation PFRESTQueryCommand

///--------------------------------------
#pragma mark - Find
///--------------------------------------

+ (nullable instancetype)findCommandForQueryState:(PFQueryState *)queryState withSessionToken:(NSString *)sessionToken error:(NSError **)error {
    NSDictionary *parameters = [self findCommandParametersForQueryState:queryState error:error];
    PFPreconditionBailOnError(parameters, error, nil);
    return [self _findCommandForClassWithName:queryState.parseClassName
                                   parameters:parameters
                                 sessionToken:sessionToken
                                        error:error];
}

+ (nullable instancetype)findCommandForClassWithName:(NSString *)className
                                              order:(NSString *)order
                                         conditions:(NSDictionary *)conditions
                                       selectedKeys:(NSSet *)selectedKeys
                                       includedKeys:(NSSet *)includedKeys
                                              limit:(NSInteger)limit
                                               skip:(NSInteger)skip
                                       extraOptions:(NSDictionary *)extraOptions
                                     tracingEnabled:(BOOL)trace
                                       sessionToken:(NSString *)sessionToken
                                              error:(NSError **)error {
    NSDictionary *parameters = [self findCommandParametersWithOrder:order
                                                         conditions:conditions
                                                       selectedKeys:selectedKeys
                                                       includedKeys:includedKeys
                                                              limit:limit
                                                               skip:skip
                                                       extraOptions:extraOptions
                                                     tracingEnabled:trace
                                                              error:error];
    PFPreconditionBailOnError(parameters, error, nil);
    return [self _findCommandForClassWithName:className
                                   parameters:parameters
                                 sessionToken:sessionToken
                                        error:error];
}

+ (nullable instancetype)_findCommandForClassWithName:(NSString *)className
                                  parameters:(NSDictionary *)parameters
                                sessionToken:(NSString *)sessionToken
                                       error:(NSError **)error {
    NSString *httpPath = [NSString stringWithFormat:@"classes/%@", className];
    PFRESTQueryCommand *command = [self commandWithHTTPPath:httpPath
                                                 httpMethod:PFHTTPRequestMethodGET
                                                 parameters:parameters
                                               sessionToken:sessionToken
                                                      error:error];
    PFPreconditionBailOnError(command, error, nil);
    return command;
}

///--------------------------------------
#pragma mark - Count
///--------------------------------------

+ (nullable instancetype)countCommandFromFindCommand:(PFRESTQueryCommand *)findCommand error:(NSError **)error {
    NSMutableDictionary *parameters = [findCommand.parameters mutableCopy];
    parameters[@"count"] = @"1";
    parameters[@"limit"] = @"0"; // Set the limit to 0, as we are not interested in results at all.
    [parameters removeObjectForKey:@"skip"];

    return [self commandWithHTTPPath:findCommand.httpPath
                          httpMethod:findCommand.httpMethod
                          parameters:[parameters copy]
                        sessionToken:findCommand.sessionToken
                               error:error];
}

///--------------------------------------
#pragma mark - Parameters
///--------------------------------------

+ (nullable NSDictionary *)findCommandParametersForQueryState:(PFQueryState *)queryState error:(NSError **)error {
    return [self findCommandParametersWithOrder:queryState.sortOrderString
                                     conditions:queryState.conditions
                                   selectedKeys:queryState.selectedKeys
                                   includedKeys:queryState.includedKeys
                                          limit:queryState.limit
                                           skip:queryState.skip
                                   extraOptions:queryState.extraOptions
                                 tracingEnabled:queryState.trace
                                          error:error];
}

+ (nullable NSDictionary *)findCommandParametersWithOrder:(NSString *)order
                                      conditions:(NSDictionary *)conditions
                                    selectedKeys:(NSSet *)selectedKeys
                                    includedKeys:(NSSet *)includedKeys
                                           limit:(NSInteger)limit
                                            skip:(NSInteger)skip
                                    extraOptions:(NSDictionary *)extraOptions
                                  tracingEnabled:(BOOL)trace
                                           error:(NSError **)error {
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

    __block BOOL encodingFailed = NO;
    __block NSError *encodingError;
    if (conditions.count > 0) {
        NSMutableDictionary *whereData = [[NSMutableDictionary alloc] init];
        [conditions enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            if ([key isEqualToString:PFQueryKeyOr]) {
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
                                                                    tracingEnabled:NO
                                                                             error:&encodingError];
                    if (!queryDict && encodingError) {
                        *stop = true;
                        encodingFailed = true;
                        return;
                    }

                    queryDict = queryDict[@"where"];
                    if (queryDict.count > 0) {
                        [newArray addObject:queryDict];
                    } else {
                        [newArray addObject:@{}];
                    }
                }
                whereData[key] = newArray;
            } else {
                id object = [self _encodeSubqueryIfNeeded:obj error:&encodingError];
                if (!object && encodingError) {
                    *stop = true;
                    encodingFailed = true;
                    return;
                }
                id pointer = [[PFPointerObjectEncoder objectEncoder] encodeObject:object error:&encodingError];
                if (!pointer && encodingError) {
                    *stop = true;
                    encodingFailed = true;
                    return;
                }
                whereData[key] = pointer;
            }
        }];

        parameters[@"where"] = whereData;
    }
    if (encodingFailed && encodingError) {
        PFSetError(error, encodingError);
        return nil;
    }

    return parameters;
}

+ (nullable id)_encodeSubqueryIfNeeded:(id)object error:(NSError * __autoreleasing *)error {
    if (![object isKindOfClass:[NSDictionary class]]) {
        return object;
    }

    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithCapacity:[object count]];
    __block BOOL encodingFailed = NO;
    __block NSError *encodingError = nil;
    [object enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([obj isKindOfClass:[PFQuery class]]) {
            PFQuery *subquery = (PFQuery *)obj;
            NSDictionary *command = [self findCommandParametersWithOrder:subquery.state.sortOrderString
                                                              conditions:subquery.state.conditions
                                                            selectedKeys:subquery.state.selectedKeys
                                                            includedKeys:subquery.state.includedKeys
                                                                    limit:subquery.state.limit
                                                                    skip:subquery.state.skip
                                                            extraOptions:subquery.state.extraOptions
                                                          tracingEnabled:NO
                                                                   error:&encodingError];
            if (!command && encodingError) {
                encodingFailed = YES;
                *stop = YES;
                return;
            }
            NSMutableDictionary *subqueryParameters = [command mutableCopy];
            subqueryParameters[@"className"] = subquery.parseClassName;
            obj = subqueryParameters;
        } else if ([obj isKindOfClass:[NSDictionary class]]) {
            obj = [self _encodeSubqueryIfNeeded:obj error:&encodingError];
            if (!obj && encodingError) {
                encodingFailed = YES;
                *stop = YES;
                return;
            }
        }
        parameters[key] = obj;
    }];
    if (encodingFailed) {
        if (error && encodingError) {
            *error = encodingError;
        }
        return nil;
    }
    return parameters;
}

@end
