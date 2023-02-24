/**
 * Copyright (c) 2016-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

@import Foundation;
@import Parse;
@import ParseLiveQuery;

#import "Message.h"

NS_ASSUME_NONNULL_BEGIN

@class ChatRoomManager;

@protocol ChatRoomManagerDataSource <NSObject>

- (PFQuery *)queryForChatRoomManager:(ChatRoomManager *)manager;
- (PFLiveQueryClient *)liveQueryClientForChatRoomManager:(ChatRoomManager *)manager;

@end

@protocol ChatRoomManagerDelegate <NSObject>

- (void)chatRoomManager:(ChatRoomManager *)manager didReceiveMessage:(Message *)message;

@end

@interface ChatRoomManager : NSObject

@property (nonatomic, assign, readonly, getter=isConnected) BOOL connected;
@property (nonatomic, weak, readonly) id<ChatRoomManagerDataSource> dataSource;
@property (nonatomic, weak, readonly) id<ChatRoomManagerDelegate> delegate;

- (instancetype)initWithDataSource:(id<ChatRoomManagerDataSource>)dataSource delegate:(id<ChatRoomManagerDelegate>)delegate;

- (void)connect;
- (void)disconnect;

@end

NS_ASSUME_NONNULL_END
