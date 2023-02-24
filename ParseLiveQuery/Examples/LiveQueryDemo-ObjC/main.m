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

#import "ChatRoomManager.h"
#import "Message.h"
#import "Room.h"

BFTask<PFUser *> *AttemptLogin() {
  puts("Enter username: ");
  char buffer[1024];
  fgets(buffer, 1024, stdin);

  NSString *username = [NSString stringWithUTF8String:buffer];

  NSString *prompt = [NSString stringWithFormat:@"Enter password for %@", username];
  NSString *password = [NSString stringWithUTF8String:getpass([prompt UTF8String])];

  return [[PFUser logInWithUsernameInBackground:username password:password] continueWithBlock:^id (BFTask<PFUser *> *task) {
    if (task.result) {
      return task.result;
    }

    puts("Login failed, please try again.");
    return AttemptLogin();
  }];
}

BFTask<Room *> *AttemptRoom() {
  puts("Enter chat room to connect to: ");
  char buffer[1024];
  fgets(buffer, 1024, stdin);

  NSString *roomName = [NSString stringWithUTF8String:buffer];

  return [[[[Room query] whereKey:@"name"
                          equalTo:roomName]
           getFirstObjectInBackground]
          continueWithBlock:^id _Nullable(BFTask * _Nonnull task) {
            if (task.result) {
              return task.result;
            }

            puts("Room not found, please try again.");
            return AttemptRoom();
          }];
}

@interface ChatRoomHandler : NSObject <ChatRoomManagerDataSource, ChatRoomManagerDelegate>

@property (nonatomic, strong, readonly) Room *room;
@property (nonatomic, strong, readonly) PFLiveQueryClient *client;

@end

@implementation ChatRoomHandler

- (instancetype)initWithRoom:(Room *)room {
  self = [super init];
  if (!self) return self;

  _room = room;
  _client = [[PFLiveQueryClient alloc] init];

  return self;
}

- (PFQuery *)queryForChatRoomManager:(ChatRoomManager *)manager {
  return [[[Message query] whereKey:@"room_name"
                            equalTo:self.room.name]
                   orderByAscending:@"createdAt"];
}

- (PFLiveQueryClient *)liveQueryClientForChatRoomManager:(ChatRoomManager *)manager {
  return _client;
}

- (void)chatRoomManager:(ChatRoomManager *)manager didReceiveMessage:(Message *)message {
  NSString *formatted = [NSString stringWithFormat:@"%@ %@ %@", message.createdAt, message.authorName, message.message];
  printf("%s\n", formatted.UTF8String);
}

@end

int main(int argc, const char * argv[]) {
  @autoreleasepool {
    [Message registerSubclass];
    [Room registerSubclass];

    [Parse initializeWithConfiguration:[ParseClientConfiguration configurationWithBlock:^(id<ParseMutableClientConfiguration> configuration) {
      configuration.applicationId = @"myAppId";
      configuration.server = @"http://localhost:1337/parse";
    }]];

    [[AttemptLogin() continueWithBlock:^id (BFTask<PFUser *> *task) {
      return AttemptRoom();
    }] continueWithBlock:^id (BFTask<Room *> *task) {
      Room *room = task.result;
      ChatRoomHandler *handler = [[ChatRoomHandler alloc] initWithRoom:room];
      ChatRoomManager *manager = [[ChatRoomManager alloc] initWithDataSource:handler delegate:handler];

      // Print out the previous messages
      PFQuery *query = [handler queryForChatRoomManager:manager];
      [[query findObjectsInBackground] continueWithBlock:^id (BFTask *task) {
        for (Message *message in task.result) {
          [handler chatRoomManager:manager didReceiveMessage:message];
        }

        [manager connect];
        return nil;
      }];

      dispatch_io_t stdinChannel = dispatch_io_create(DISPATCH_IO_STREAM, STDIN_FILENO, dispatch_get_main_queue(), ^(int error) {
        perror("dispatch_io_create");
      });

      dispatch_io_set_low_water(stdinChannel, 1);
      dispatch_io_read(stdinChannel, 0, SIZE_MAX, dispatch_get_main_queue(), ^(bool done, dispatch_data_t data, int error) {
        NSString *messageText = [[[NSString alloc] initWithData:(NSData *)data
                                                       encoding:NSUTF8StringEncoding]
                                stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];


        Message *message = [[Message alloc] init];
        message.author = [PFUser currentUser];
        message.authorName = [PFUser currentUser].username;
        message.message = messageText;
        message.room = room;
        message.roomName = room.name;

        [message saveInBackground];
      });

      return nil;
    }];

    dispatch_main();
  }

  return 0;
}
