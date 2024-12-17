//
//  init.mm
//  FixMRES
//
//  Created by Jinwoo Kim on 12/17/24.
//

#import <Foundation/Foundation.h>
#import <Vision/Vision.h>
#import <objc/message.h>
#import <objc/runtime.h>

namespace fm_VNRequest {
namespace performInContext_error_ {
BOOL (*original)(VNRequest *self, SEL _cmd, id context, NSError * _Nullable __autoreleasing * _Nullable errorOut);
BOOL custom(VNRequest *self, SEL _cmd, id context, NSError * _Nullable __autoreleasing * _Nullable errorOut) {
    BOOL result = original(self, _cmd, context, errorOut);
    
    if (!result and (errorOut != NULL)) {
        *errorOut = nil;
    }
    
    return YES;
}
void swizzle() {
    Method method = class_getInstanceMethod([VNRequest class], sel_registerName("performInContext:error:"));
    original = reinterpret_cast<decltype(original)>(method_getImplementation(method));
    method_setImplementation(method, reinterpret_cast<IMP>(custom));
}
}
}

__attribute__((constructor)) void init(void) {
    fm_VNRequest::performInContext_error_::swizzle();
}
