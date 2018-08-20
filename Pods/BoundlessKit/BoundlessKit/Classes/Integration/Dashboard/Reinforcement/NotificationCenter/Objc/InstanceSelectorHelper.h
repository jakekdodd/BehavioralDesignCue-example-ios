//
//  InstanceSelectorHelper.h
//  Pods
//
//  Created by Akash Desai on 8/15/17.
//
//

#ifndef InstanceSelectorHelper_h
#define InstanceSelectorHelper_h

@interface InstanceSelectorHelper : NSObject

typedef void (^ InstanceSelectionBlock)(Class targetClass,  SEL targetSelector, id target, id sender);

+ (SEL) createMethodBeforeInstance:(Class)targetClass selector:(SEL)targetSelector withBlock:(InstanceSelectionBlock) block;

+ (BOOL) injectSelector:(Class) anotherClass :(SEL) anotherSelector :(Class) originalClass :(SEL) orignalSelector;

+ (NSArray*) classesConforming: (Protocol*) protocol;

+ (NSArray*) classesInheriting: (Class) parentClass;

@end

#endif /* InstanceSelectorHelper_h */
