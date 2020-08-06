//
//  SignInWithAppleTests.m
//  SignInWithAppleTests
//
//  Created by Darren Black on 03/01/2020.
//  Copyright © 2020 Parse Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "PFAppleUtils.h"
@import OCMock;

@interface SignInWithAppleTests : XCTestCase

@end

@interface PFAppleUtils ()

+ (BFTask<NSDictionary *> *)logInInBackgroundWithManager:(PFAppleLoginManager *)manager;

@end

@interface PFAppleLoginManager ()

@property (weak, nonatomic) ASAuthorizationController *controller;

@end

@interface FakeAuth : NSObject

@property (nonatomic, strong) id provider;
@property (nonatomic, strong) id credential;

@end

@implementation FakeAuth

@end

@interface FakeCredential : NSObject

@property (nonatomic, strong) NSString *user;
@property (nonatomic, strong) NSPersonNameComponents *fullName;
@property (nonatomic, strong) NSData *identityToken;

@end

@implementation FakeCredential

@end

@implementation SignInWithAppleTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testLoginSuccess {
    
    // Create test ASAuthorization and ASAuthorizationAppleIDCredential
    FakeAuth *fakeAuth = [FakeAuth new];
    FakeCredential *cred = [FakeCredential new];
    NSString *aString = [NSUUID UUID].UUIDString;
    cred.user = aString;
    NSPersonNameComponents *name = [[NSPersonNameComponents alloc] init];
    name.givenName = @"Test";
    name.familyName = @"User";
    cred.fullName = name;
    NSData *token = [aString dataUsingEncoding:NSUTF8StringEncoding];
    cred.identityToken = token;
    fakeAuth.credential = cred;
    
    // Create stub for PFUser logInWithAuthTypeInBackground
    id mockUser = OCMClassMock([PFUser class]);
    NSDictionary *authData = @{@"token" : aString,
                               @"id" : aString };
    NSDictionary *result = @{ @"user" : aString,
                              @"name" : name };
    OCMStub(ClassMethod([mockUser logInWithAuthTypeInBackground:@"apple" authData:authData])).andReturn([BFTask taskWithResult:result]);
    
    // Create the login task
    PFAppleLoginManager *manager = [PFAppleLoginManager new];
    BFTask<NSDictionary *> *logInTask = [PFAppleUtils logInInBackgroundWithManager:manager];
    
    XCTestExpectation *expect = [self expectationWithDescription:@"Task should complete."];
    [logInTask continueWithSuccessBlock:^id _Nullable(BFTask<NSDictionary *> * _Nonnull t) {
        [expect fulfill];
        return nil;
    }];
    
    // Call the success callback as Apple would
    [manager authorizationController:manager.controller didCompleteWithAuthorization:(ASAuthorization *)fakeAuth];
    [self waitForExpectations:@[expect] timeout:2];
    
    [mockUser stopMocking];
    
}

- (void)testPFUserLoginFails {
    // Create test ASAuthorization and ASAuthorizationAppleIDCredential
    FakeAuth *fakeAuth = [FakeAuth new];
    FakeCredential *cred = [FakeCredential new];
    NSString *aString = [NSUUID UUID].UUIDString;
    cred.user = aString;
    NSPersonNameComponents *name = [[NSPersonNameComponents alloc] init];
    name.givenName = @"Test";
    name.familyName = @"User";
    cred.fullName = name;
    NSData *token = [aString dataUsingEncoding:NSUTF8StringEncoding];
    cred.identityToken = token;
    fakeAuth.credential = cred;
    
    // Create failing stub for PFUser logInWithAuthTypeInBackground
    id mockUser = OCMClassMock([PFUser class]);
    NSDictionary *authData = @{@"token" : aString,
                               @"id" : aString };
    NSError *err = [[NSError alloc] initWithDomain:@"org.parseplatform.error" code:1337 userInfo:nil];
    OCMStub(ClassMethod([mockUser logInWithAuthTypeInBackground:@"apple" authData:authData])).andReturn([BFTask taskWithError:err]);
    
    // Create the login task
    PFAppleLoginManager *manager = [PFAppleLoginManager new];
    BFTask<NSDictionary *> *logInTask = [PFAppleUtils logInInBackgroundWithManager:manager];
    
    XCTestExpectation *expect = [self expectationWithDescription:@"Task should fail."];
    [logInTask continueWithBlock:^id _Nullable(BFTask<NSDictionary *> * _Nonnull t) {
        if (t.error) {
            [expect fulfill];
        }
        return nil;
    }];
    
    // Call the success callback as Apple would
    [manager authorizationController:manager.controller didCompleteWithAuthorization:(ASAuthorization *)fakeAuth];
    [self waitForExpectations:@[expect] timeout:2];
    
    [mockUser stopMocking];
}

- (void)testAppleAuthCompletesWithError {
    
    // Create the login task
    PFAppleLoginManager *manager = [PFAppleLoginManager new];
    BFTask<NSDictionary *> *logInTask = [PFAppleUtils logInInBackgroundWithManager:manager];
    
    XCTestExpectation *expect = [self expectationWithDescription:@"Task should fail."];
    [logInTask continueWithBlock:^id _Nullable(BFTask<NSDictionary *> * _Nonnull t) {
        if (t.error) {
            [expect fulfill];
        }
        return nil;
    }];
    
    // Call the failure callback as Apple would
    NSError *err = [[NSError alloc] initWithDomain:@"org.parseplatform.error" code:1337 userInfo:nil];
    [manager authorizationController:manager.controller didCompleteWithError:err];
    [self waitForExpectations:@[expect] timeout:2];
    
}

@end
