#import "LoShotSet.h"

@interface LoShotSet ()
@property (nonatomic) NSMutableArray *shotsSet;
@property (nonatomic) NSUInteger size;
@end

@implementation LoShotSet

- (id)init {
    return [self initForSize:4];
}

- (id)initForSize: (NSUInteger) size {
    self = [super init];
    if (self) {
        self.shotsSet = [NSMutableArray arrayWithCapacity:size];
        self.size = size;
    }
    return self;
}

- (void)addShot:(UIImage *)image {
    if (self.shotsSet.count < self.size) {
        [self.shotsSet addObject:image];
    }
}

- (NSArray*)getShotsArray {
    return self.shotsSet;
}

- (NSUInteger)getCount {
    return self.shotsSet.count;
}

@end
