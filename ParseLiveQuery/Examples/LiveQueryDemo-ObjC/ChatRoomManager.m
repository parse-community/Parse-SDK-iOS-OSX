/**
 * Copyright (c) 2016-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "ChatRoomManager.h"

@interface ChatRoomManager()

@property (nonatomic, strong) PFLiveQueryClient *client;
@property (nonatomic, strong) PFQuery *query;
@property (nonatomic, strong) PFLiveQuerySubscription *subscription;

@end

@implementation ChatRoomManager

- (instancetype)initWithDataSource:(id<ChatRoomManagerDataSource>)dataSource delegate:(id<ChatRoomManagerDelegate>)delegate{
  self = [super init];
  if (!self) return self;

  _dataSource = dataSource;
  _delegate = delegate;

  return self;
}

- (BOOL)isConnected {
  return self.subscription != nil;
}

- (void)connect {
  self.client = [self.dataSource liveQueryClientForChatRoomManager:self];
  self.query = [self.dataSource queryForChatRoomManager:self];

  __weak typeof(self) weakSelf = self;

  self.subscription = [[self.client subscribeToQuery:self.query] addCreateHandler:^(PFQuery *query, PFObject *message) {
    [weakSelf.delegate chatRoomManager:weakSelf didReceiveMessage:(Message *)message];
  }];
}

- (void)disconnect {
  self.client = nil;
  self.query = nil;
  self.subscription = nil;
}

@end
