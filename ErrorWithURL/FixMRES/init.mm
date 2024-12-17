//
//  init.mm
//  FixMRES
//
//  Created by Jinwoo Kim on 12/17/24.
//

#import <Foundation/Foundation.h>
#import <CoreImage/CoreImage.h>
#import <Vision/Vision.h>
#import <ImageIO/ImageIO.h>
#import <objc/message.h>
#import <objc/runtime.h>
#include <dlfcn.h>

static void *key = &key;

namespace fm_VNImageRequestHandler {
namespace initWithCIImage_orientation_options_ {
VNImageRequestHandler * (*original)(VNImageRequestHandler *self, SEL _cmd, CIImage *image, CGImagePropertyOrientation orientation, NSDictionary<NSString *,id> *options);
VNImageRequestHandler * custom(VNImageRequestHandler *self, SEL _cmd, CIImage *image, CGImagePropertyOrientation orientation, NSDictionary<NSString *,id> *options) {
    self = original(self, _cmd, image, orientation, options);
    
    if (self) {
        id imageBuffer = reinterpret_cast<id (*)(id, SEL)>(objc_msgSend)(self, sel_registerName("imageBuffer"));
        objc_setAssociatedObject(imageBuffer, key, image.url, OBJC_ASSOCIATION_COPY_NONATOMIC);
    }
    
    return self;
}
void swizzle() {
    Method method = class_getInstanceMethod([VNImageRequestHandler class], @selector(initWithCIImage:orientation:options:));
    original = reinterpret_cast<decltype(original)>(method_getImplementation(method));
    method_setImplementation(method, reinterpret_cast<IMP>(custom));
}
}
}

namespace fm_VNRequestPerformingContext {
namespace initWithSession_requestPerformer_imageBuffer_forensics_observationsCache_ {
id (*original)(id self, SEL _cmd, id session, id performer, id imageBuffer, id forensics, id observationsCache);
id custom(id self, SEL _cmd, id session, id performer, id imageBuffer, id forensics, id observationsCache) {
    self = original(self, _cmd, session, performer, imageBuffer, forensics, observationsCache);
    
    if (self) {
        NSURL *url = objc_getAssociatedObject(imageBuffer, key);
        objc_setAssociatedObject(self, key, url, OBJC_ASSOCIATION_COPY_NONATOMIC);
    }
    
    return self;
}
void swizzle() {
    Method method = class_getInstanceMethod(objc_lookUpClass("VNRequestPerformingContext"), sel_registerName("initWithSession:requestPerformer:imageBuffer:forensics:observationsCache:"));
    original = reinterpret_cast<decltype(original)>(method_getImplementation(method));
    method_setImplementation(method, reinterpret_cast<IMP>(custom));
}
}
}

namespace fm_VNRequest {
namespace performInContext_error_ {
BOOL (*original)(VNRequest *self, SEL _cmd, id context, NSError * _Nullable __autoreleasing * _Nullable errorOut);
BOOL custom(VNRequest *self, SEL _cmd, id context, NSError * _Nullable __autoreleasing * _Nullable errorOut) {
    BOOL result = original(self, _cmd, context, errorOut);
    
    if (errorOut != NULL) {
        NSError * _Nullable error = *errorOut;
        if (error != nil) {
            NSURL *url = objc_getAssociatedObject(context, key);
            
            if (url != nil) {
                NSString *description = error.userInfo[NSLocalizedDescriptionKey];
                if (description == nil) {
                    description = url.path;
                } else {
                    description = [NSString stringWithFormat:@"%@, %@", url.path, description];
                }
                
                *errorOut = [NSError errorWithDomain:error.domain code:error.code userInfo:@{NSLocalizedDescriptionKey: description}];
            }
        }
    }
    
    return result;
}
void swizzle() {
    Method method = class_getInstanceMethod([VNRequest class], sel_registerName("performInContext:error:"));
    original = reinterpret_cast<decltype(original)>(method_getImplementation(method));
    method_setImplementation(method, reinterpret_cast<IMP>(custom));
}
}
}

__attribute__((constructor)) void init(void) {
    fm_VNImageRequestHandler::initWithCIImage_orientation_options_::swizzle();
    fm_VNRequestPerformingContext::initWithSession_requestPerformer_imageBuffer_forensics_observationsCache_::swizzle();
    fm_VNRequest::performInContext_error_::swizzle();
}
