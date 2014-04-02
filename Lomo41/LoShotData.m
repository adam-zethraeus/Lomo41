#import "LoShotData.h"

#include <libkern/OSAtomic.h>

@interface LoShotData()
@property (nonatomic, weak) id <LoShotDataDelegate> delegate;
@end

@implementation LoShotData {
    int32_t _count;
}

- (id)initWithDelegate:(id<LoShotDataDelegate>)delegate{
    self = [super init];
    if (self) {
        self.delegate = delegate;
        _count = 0;
    }
    return self;
}

- (void)addImage:(UIImage *)image toLocation:(PaneLocation)location {
    int32_t newCount = OSAtomicIncrement32Barrier(&_count);
    switch (location) {
        case LEFTMOST:
            self.leftmost = image;
            break;
        case MIDDLE_LEFT:
            self.middle_left = image;
            break;
        case MIDDLE_RIGHT:
            self.middle_right = image;
            break;
        case RIGHTMOST:
            self.rightmost = image;
            break;
    }
    if (newCount == 4) {
        NSAssert(self.leftmost != nil, @"lacking image");
        NSAssert(self.middle_left != nil, @"lacking image");
        NSAssert(self.middle_right != nil, @"lacking image");
        NSAssert(self.rightmost != nil, @"lacking image");
        [self.delegate dataComplete:self];
    }
}

- (void)invalidate {
    self.leftmost = nil;
    self.middle_left = nil;
    self.middle_right = nil;
    self.rightmost = nil;
}

- (NSInteger)getCount {
    return (NSInteger)_count;
}

@end
