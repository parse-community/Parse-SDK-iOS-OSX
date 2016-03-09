/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFHash.h"

#import <CommonCrypto/CommonDigest.h>

//
// Thank you Thomas Wang for 32/64 bit mix hash
// http://www.concentric.net/~Ttwang/tech/inthash.htm
//
// Above link is now dead, please visit
// http://web.archive.org/web/20121102023700/http://www.concentric.net/~Ttwang/tech/inthash.htm
//

extern NSUInteger PFIntegerPairHash(NSUInteger a, NSUInteger b) {
    return PFLongHash(((unsigned long long)a) << 32 | b);
}

extern NSUInteger PFDoublePairHash(double a, double b) {
    return PFIntegerPairHash(PFDoubleHash(a), PFDoubleHash(b));
}

extern NSUInteger PFDoubleHash(double d) {
    union {
        double key;
        uint64_t bits;
    } u;
    u.key = d;
    return PFLongHash(u.bits);
}

extern NSUInteger PFLongHash(unsigned long long l) {
    l = (~l) + (l << 18);           // key = (key << 18) - key - 1;
    l ^= (l >> 31);
    l *=  21;                       // key = (key + (key << 2)) + (key << 4);
    l ^= (l >> 11);
    l += (l << 6);
    l ^= (l >> 22);
    return (NSUInteger)l;
}

extern NSString *PFMD5HashFromData(NSData *data) {
    unsigned char md[CC_MD5_DIGEST_LENGTH];

    // NOTE: `__block` variables of a struct type seem to be bugged. The compiler emits instructions to read
    // from the stack past where they're supposed to exist. This fixes that, by only using a traditional pointer.
    CC_MD5_CTX ctx_val = { 0 };
    CC_MD5_CTX *ctx_ptr = &ctx_val;
    CC_MD5_Init(ctx_ptr);
    [data enumerateByteRangesUsingBlock:^(const void *bytes, NSRange byteRange, BOOL *stop) {
        CC_MD5_Update(ctx_ptr , bytes, (CC_LONG)byteRange.length);
    }];
    CC_MD5_Final(md, ctx_ptr);

    NSString *string = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                        md[0], md[1],
                        md[2], md[3],
                        md[4], md[5],
                        md[6], md[7],
                        md[8], md[9],
                        md[10], md[11],
                        md[12], md[13],
                        md[14], md[15]];
    return string;
}

extern NSString *PFMD5HashFromString(NSString *string) {
    return PFMD5HashFromData([string dataUsingEncoding:NSUTF8StringEncoding]);
}
