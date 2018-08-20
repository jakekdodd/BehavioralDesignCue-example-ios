//
//  InstanceSelectorHelper.m
//  Pods
//
//  Created by Akash Desai on 8/15/17.
//
//

#import <InstanceSelectorHelper.h>

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@implementation InstanceSelectorHelper

+ (SEL) createMethodBeforeInstance:(Class)targetClass selector:(SEL)targetSelector withBlock:(InstanceSelectionBlock) block {
    Method originalMethod = class_getInstanceMethod(targetClass, targetSelector);
    if (originalMethod == nil) {
        return nil;
    }
    
    SEL newSelector = NSSelectorFromString([NSString stringWithFormat:@"notifyBefore__%@", NSStringFromSelector(targetSelector)]);
    if (class_inheritsInstanceSelector(targetClass, newSelector)) {
        return newSelector;
    }
    const char* methodTypeEncoding = method_getTypeEncoding(originalMethod);
    NSString* methodTypeEncodingString = [NSString stringWithUTF8String:methodTypeEncoding];
    
    BOOL success;
    if (compareMethodCreationTypeEncodings(methodTypeEncodingString, [UIApplication self], @selector(sendAction:to:from:forEvent:))) {
        success = [InstanceSelectorHelper addMethodBlockForSendAction :targetClass :targetSelector :newSelector :block];
    } else if (compareMethodCreationTypeEncodings(methodTypeEncodingString, [InstanceSelectorHelper self], @selector(templateMethodWithNoParam))) {
        success = [InstanceSelectorHelper addMethodBlockWithNoParam:targetClass :targetSelector :newSelector :block];
    } else if (compareMethodCreationTypeEncodings(methodTypeEncodingString, [InstanceSelectorHelper self], @selector(templateMethodWithObjectParam:))) {
        success = [InstanceSelectorHelper addMethodBlockWithObjectParam :targetClass :targetSelector :newSelector :block];
    } else if (compareMethodCreationTypeEncodings(methodTypeEncodingString, [InstanceSelectorHelper self], @selector(templateMethodWithObjectObjectParam::))) {
        success = [InstanceSelectorHelper addMethodBlockWithObjectObjectParam:targetClass :targetSelector :newSelector :block];
    } else if (compareMethodCreationTypeEncodings(methodTypeEncodingString, [InstanceSelectorHelper self], @selector(templateMethodWithObjectBoolObjectParam:::))) {
        success = [InstanceSelectorHelper addMethodBlockWithObjectBoolObjectParam:targetClass :targetSelector :newSelector :block];
    } else if (compareMethodCreationTypeEncodings(methodTypeEncodingString, [InstanceSelectorHelper self], @selector(templateMethodWithBoolParam:))) {
        success = [InstanceSelectorHelper addMethodBlockWithBoolParam:targetClass :targetSelector :newSelector :block];
    } else {
//        NSLog(@"Unsupported encoding:%@ other:%@", methodTypeEncodingString, [NSString stringWithUTF8String: method_getTypeEncoding(class_getInstanceMethod(UIApplication.self, @selector(sendAction:to:from:forEvent:)))]);
        return nil;
    }
    
    return success ? newSelector : nil;
}

+ (BOOL) addMethodBlockForSendAction :(Class) targetClass :(SEL) targetSelector :(SEL) newSelector :(InstanceSelectionBlock) newBlock {
    BOOL success = true;
    
    const char* methodEncoding = method_getTypeEncoding(class_getInstanceMethod(targetClass, targetSelector));
    if (!class_inheritsInstanceSelector(targetClass, targetSelector)) {
        IMP callSuperImp = imp_implementationWithBlock(^(id self, SEL action, id target, id sender, UIEvent* event) {
            ((BOOL (*)(id, SEL, SEL, id, id, UIEvent*)) [class_getSuperclass(targetClass) instanceMethodForSelector: targetSelector]) (self, newSelector, action, target, sender, event);
        });
        success = success && class_addMethod(targetClass, targetSelector, callSuperImp, methodEncoding);
    }
    
    IMP newImp = imp_implementationWithBlock(^(id self, SEL action, id target, id sender, UIEvent* event) {
        IMP targetImp = [targetClass instanceMethodForSelector: newSelector];
        if (!self || !targetImp) {return;}
        newBlock([target class], action, target, sender);
        ((BOOL(*) (id, SEL, SEL, id, id, UIEvent*)) targetImp) (self, newSelector, action, target, sender, event);
    });
    success = success && class_addMethod(targetClass, newSelector, newImp, methodEncoding);
    
    return success;
}

- (void) templateMethodWithNoParam { }
+ (BOOL) addMethodBlockWithNoParam :(Class) targetClass :(SEL) targetSelector :(SEL) newSelector :(InstanceSelectionBlock) newBlock {
    BOOL success = true;
    
    const char* methodEncoding = method_getTypeEncoding(class_getInstanceMethod(targetClass, targetSelector));
    if (!class_inheritsInstanceSelector(targetClass, targetSelector)) {
        IMP callSuperImp = imp_implementationWithBlock(^(id self) {
            ((void (*)(id, SEL)) [class_getSuperclass(targetClass) instanceMethodForSelector: targetSelector]) (self, targetSelector);
        });
        success = success && class_addMethod(targetClass, targetSelector, callSuperImp, methodEncoding);
    }
    
    IMP newImp = imp_implementationWithBlock(^(id self) {
        IMP targetImp = [targetClass instanceMethodForSelector: newSelector];
        if (!self || !targetImp) {return;}
        newBlock(targetClass, targetSelector, self, nil);
        ((void(*) (id, SEL)) targetImp) (self, targetSelector);
    });
    success = success && class_addMethod(targetClass, newSelector, newImp, methodEncoding);
    
    return success;
}

- (void) templateMethodWithObjectParam :(id) param { }
+ (BOOL) addMethodBlockWithObjectParam :(Class) targetClass :(SEL) targetSelector :(SEL) newSelector :(InstanceSelectionBlock) newBlock {
    BOOL success = true;
    
    const char* methodEncoding = method_getTypeEncoding(class_getInstanceMethod(targetClass, targetSelector));
    if (!class_inheritsInstanceSelector(targetClass, targetSelector)) {
        IMP callSuperImp = imp_implementationWithBlock(^(id self, id param) {
            ((void(*) (id, SEL, id)) [class_getSuperclass(targetClass) instanceMethodForSelector: targetSelector]) (self, targetSelector, param);
        });
        success = success && class_addMethod(targetClass, targetSelector, callSuperImp, methodEncoding);
    }
    
    IMP newImp = imp_implementationWithBlock(^(id self, id param) {
        IMP targetImp = [targetClass instanceMethodForSelector: newSelector];
        if (!self || !targetImp) {return;}
        newBlock(targetClass, targetSelector, self, param);
        ((void(*) (id, SEL, id)) targetImp) (self, targetSelector, param);
    });
    success = success && class_addMethod(targetClass, newSelector, newImp, methodEncoding);
    
    return success;
}

- (void) templateMethodWithObjectObjectParam :(id) param1 :(id) param2 { }
+ (BOOL) addMethodBlockWithObjectObjectParam :(Class) targetClass :(SEL) targetSelector :(SEL) newSelector :(InstanceSelectionBlock) newBlock {
    BOOL success = true;
    
    const char* methodEncoding = method_getTypeEncoding(class_getInstanceMethod(targetClass, targetSelector));
    if (!class_inheritsInstanceSelector(targetClass, targetSelector)) {
        IMP callSuperImp = imp_implementationWithBlock(^(id self, id param1, id param2) {
            ((void(*) (id, SEL, id, id)) [class_getSuperclass(targetClass) instanceMethodForSelector:targetSelector]) (self, newSelector, param1, param2);
        });
        success = success && class_addMethod(targetClass, targetSelector, callSuperImp, methodEncoding);
    }
    
    IMP newImp = imp_implementationWithBlock(^(id self, id param1, id param2) {
        IMP targetImp = [targetClass instanceMethodForSelector: newSelector];
        if (!self || !targetImp) {return;}
        newBlock(targetClass, targetSelector, self, param1);
        ((void(*) (id, SEL, id, id)) targetImp) (self, newSelector, param1, param2);
    });
    success = success && class_addMethod(targetClass, newSelector, newImp, methodEncoding);
    
    return success;
}

- (void) templateMethodWithObjectBoolObjectParam :(id) param1 :(BOOL) param2 :(id) param3 { }
+ (BOOL) addMethodBlockWithObjectBoolObjectParam :(Class) targetClass :(SEL) targetSelector :(SEL) newSelector :(InstanceSelectionBlock) newBlock {
    BOOL success = true;
    
    const char* methodEncoding = method_getTypeEncoding(class_getInstanceMethod(targetClass, targetSelector));
    if (!class_inheritsInstanceSelector(targetClass, targetSelector)) {
        IMP callSuperImp = imp_implementationWithBlock(^(id self, id param1, BOOL param2, id param3) {
            ((void(*) (id, SEL, id, bool, id)) [class_getSuperclass(targetClass) instanceMethodForSelector:targetSelector]) (self, newSelector, param1, param2, param3);
        });
        success = success && class_addMethod(targetClass, targetSelector, callSuperImp, methodEncoding);
    }
    
    IMP newImp = imp_implementationWithBlock(^(id self, id param1, BOOL param2, id param3) {
        IMP targetImp = [targetClass instanceMethodForSelector: newSelector];
        if (!self || !targetImp) {return;}
        newBlock(targetClass, targetSelector, self, param1);
        ((void(*) (id, SEL, id, bool, id)) targetImp) (self, newSelector, param1, param2, param3);
    });
    success = success && class_addMethod(targetClass, newSelector, newImp, methodEncoding);
    
    return success;
}

- (void) templateMethodWithBoolParam :(bool) param1 { }
+ (BOOL) addMethodBlockWithBoolParam :(Class) targetClass :(SEL) targetSelector :(SEL) newSelector :(InstanceSelectionBlock) newBlock {
    BOOL success = true;
    
    const char* methodEncoding = method_getTypeEncoding(class_getInstanceMethod(targetClass, targetSelector));
    if (!class_inheritsInstanceSelector(targetClass, targetSelector)) {
        //        NSLog(@"Overriding selector <%@> for class <%@>", NSStringFromSelector(targetSelector), NSStringFromClass(targetClass));
        IMP callSuperImp = imp_implementationWithBlock(^(id self, bool param) {
            ((void (*)(id, SEL, bool))[class_getSuperclass(targetClass) instanceMethodForSelector:targetSelector])(self, targetSelector, param);
        });
        success = success && class_addMethod(targetClass, targetSelector, callSuperImp, methodEncoding);
    }
    
    IMP newImp = imp_implementationWithBlock(^(id self, bool param) {
        IMP targetImp = [targetClass instanceMethodForSelector: newSelector];
        if (!self || !targetImp) {return;}
        newBlock(targetClass, targetSelector, self, nil);
        ((void(*) (id, SEL, bool)) targetImp) (self, newSelector, param);
    });
    success = success && class_addMethod(targetClass, newSelector, newImp, methodEncoding);
    
    return success;
}

BOOL compareMethodCreationTypeEncodings(NSString* candidate, Class templateClass, SEL templateSelector) {
    Method templateMethod = class_getInstanceMethod(templateClass, templateSelector);
    if (templateMethod == nil) {
        return false;
    }
    const char* templateMethodTypeEncoding = method_getTypeEncoding(templateMethod);
    
    NSString* templateMethodTypeEncodingString = [NSString stringWithUTF8String:templateMethodTypeEncoding];
    return [templateMethodTypeEncodingString isEqualToString:candidate];
}

BOOL class_inheritsInstanceSelector(Class aClass, SEL aSelector) {
    if (class_getInstanceMethod(aClass, aSelector) == NULL) {
        return false;
    }
    Class superClass = class_getSuperclass(aClass);
    return superClass == nil || class_getInstanceMethod(superClass, aSelector) == nil || [aClass instanceMethodForSelector: aSelector] != [superClass instanceMethodForSelector: aSelector];
}


+ (BOOL) injectSelector:(Class) anotherClass :(SEL) anotherSelector :(Class) originalClass :(SEL) orignalSelector {
//    NSLog(@"Injecting selector %@ for class %@ with %@", NSStringFromSelector(orignalSelector), NSStringFromClass(originalClass), NSStringFromSelector(anotherSelector));
    Method newMeth = class_getInstanceMethod(anotherClass, anotherSelector);
    IMP imp = method_getImplementation(newMeth);
    const char* methodTypeEncoding = method_getTypeEncoding(newMeth);
    
    BOOL existing = class_getInstanceMethod(originalClass, orignalSelector) != NULL;
    
    if (existing) {
        class_addMethod(originalClass, anotherSelector, imp, methodTypeEncoding);
        newMeth = class_getInstanceMethod(originalClass, anotherSelector);
        Method orgMeth = class_getInstanceMethod(originalClass, orignalSelector);
        method_exchangeImplementations(orgMeth, newMeth);
    } else {
        class_addMethod(originalClass, orignalSelector, imp, methodTypeEncoding);
    }
    
    return existing;
}

+ (NSArray*) classesConforming: (Protocol*) protocol {
    
    int numClasses = objc_getClassList(NULL, 0);
    Class *classes = (Class *)malloc(sizeof(Class) * numClasses);
    numClasses = objc_getClassList(classes, numClasses);
    
    NSMutableArray *result = [NSMutableArray array];
    for (NSInteger i = 0; i < numClasses; i++) {
        Class class = classes[i];
        Class superClass = class_getSuperclass(class);
        if (class_conformsToProtocol(class, protocol) && (superClass == nil || !class_conformsToProtocol(superClass, protocol))) {
            [result addObject:classes[i]];
//            NSLog(@"Found for protocol:%@ class:%@", protocol, class);
        }
    }
    
    free(classes);
    
    return result;
}

+ (NSArray*) classesInheriting: (Class) parentClass {
    
    int numClasses = objc_getClassList(NULL, 0);
    Class *classes = (Class *)malloc(sizeof(Class) * numClasses);
    numClasses = objc_getClassList(classes, numClasses);
    
    NSMutableArray *result = [NSMutableArray array];
    for (NSInteger i = 0; i < numClasses; i++) {
        Class superClass = classes[i];
        
        while(superClass && superClass != parentClass) {
            superClass = class_getSuperclass(superClass);
        }
        
        if (superClass) {
            [result addObject:classes[i]];
        }
    }
    
    free(classes);
    
    return result;
}

@end
