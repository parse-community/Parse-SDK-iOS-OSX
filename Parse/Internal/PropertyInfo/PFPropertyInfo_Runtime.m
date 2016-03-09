/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFPropertyInfo_Runtime.h"

#import <objc/message.h>
#import <objc/runtime.h>

/**
 This macro is really interesting. Because ARC will insert implicit retains, releases and other memory managment code
 that we don't want here, we have to basically trick ARC into treating the functions we want as functions with type
 `void *`. The way we do that is actually via the linker - instead of coming up with some crazy macro to forward all
 arguments along to the correct function, especially when some of these functions aren't in any public headers.

 They are, however, well defined, according to the clang official ARC runtime support document:
 http://clang.llvm.org/docs/AutomaticReferenceCounting.html#id55

 That means this is unlikely to ever break.

 The weakref attribute is documented here:
 https://gcc.gnu.org/onlinedocs/gcc/Common-Function-Attributes.html#Common-Function-Attributes

 And we use this to make sure our type-invariant functions actually call the proper underlying ones.
 */
#define NO_TYPECHECK_SYMBOL(ret, fn, args...) static ret fn ## _noTypeCheck (args) __attribute__((weakref(#fn)));
#define OBJECT_GETOFFSET_PTR(obj, offset) (void *) ((uintptr_t)obj + offset)

NO_TYPECHECK_SYMBOL(void *, objc_loadWeak, void **);

NO_TYPECHECK_SYMBOL(void *, objc_storeWeak, void **, void *);
NO_TYPECHECK_SYMBOL(void *, objc_storeStrong, void **, void *);

NO_TYPECHECK_SYMBOL(void *, objc_autorelease, void *);
NO_TYPECHECK_SYMBOL(void *, objc_retainAutorelease, void *);

void object_getIvarValue_safe(__unsafe_unretained id obj, Ivar ivar, void *toMemory, uint8_t associationType) {
    ptrdiff_t offset = ivar_getOffset(ivar);
    void *location = OBJECT_GETOFFSET_PTR(obj, offset);

    switch (associationType) {
        case PFPropertyInfoAssociationTypeDefault:
            [NSException raise:NSInvalidArgumentException format:@"Invalid association type Default!"];
            break;

        case PFPropertyInfoAssociationTypeAssign: {
            NSUInteger size = 0;
            NSGetSizeAndAlignment(ivar_getTypeEncoding(ivar), &size, NULL);

            memcpy(toMemory, location, size);
            break;
        }

        case PFPropertyInfoAssociationTypeWeak: {
            void *results = objc_loadWeak_noTypeCheck(location);

            memcpy(toMemory, &results, sizeof(id));
            break;
        }

        case PFPropertyInfoAssociationTypeStrong:
        case PFPropertyInfoAssociationTypeCopy:
        case PFPropertyInfoAssociationTypeMutableCopy: {
            void *objectValue = *(void **)location;
            objectValue = objc_retainAutorelease_noTypeCheck(objectValue);

            memcpy(toMemory, &objectValue, sizeof(id));
            break;
        }
    }
}

void object_setIvarValue_safe(__unsafe_unretained id obj, Ivar ivar, void *fromMemory, uint8_t associationType) {
    ptrdiff_t offset = ivar_getOffset(ivar);
    void *location = OBJECT_GETOFFSET_PTR(obj, offset);

    NSUInteger size = 0;
    NSGetSizeAndAlignment(ivar_getTypeEncoding(ivar), &size, NULL);

    void *newValue = NULL;

    switch (associationType) {
        case PFPropertyInfoAssociationTypeDefault:
            [NSException raise:NSInvalidArgumentException format:@"Invalid association type Default!"];
            return;

        case PFPropertyInfoAssociationTypeAssign: {
            memcpy(location, fromMemory, size);
            return;
        }

        case PFPropertyInfoAssociationTypeWeak: {
            objc_storeWeak_noTypeCheck(location, *(void **)fromMemory);
            return;
        }

        case PFPropertyInfoAssociationTypeStrong:
            newValue = *(void **)fromMemory;
            break;

        case PFPropertyInfoAssociationTypeCopy:
        case PFPropertyInfoAssociationTypeMutableCopy: {
            SEL command = (associationType == PFPropertyInfoAssociationTypeCopy) ? @selector(copy)
                                                                                 : @selector(mutableCopy);


            void *(*objc_msgSend_casted)(void *, SEL) = (void *)objc_msgSend;
            void *oldValue = *(void **)fromMemory;

            newValue = objc_msgSend_casted(oldValue, command);
            newValue = objc_autorelease_noTypeCheck(newValue);
            break;
        }
    }
    
    objc_storeStrong_noTypeCheck(location, newValue);
}
