#import "LoPhotoProcessor.h"

@implementation LoPhotoProcessor {
    NSMutableArray *_shotDataArray;
}

- (id)init {
    self = [super init];
    if (self) {
        _shotDataArray = [[NSMutableArray alloc] init];
    }
    return self;
}

- (NSUInteger)getCount {
    return [_shotDataArray count];
}

- (LoShotData *)newShotHandle {
    LoShotData *data = [[LoShotData alloc] initWithDelegate:self];
    return data;
}

- (void)processImage:(UIImage *)image
          atLocation:(PaneLocation)location
            withData:(LoShotData *)data {
    //TODO: do processing
    [data addImage:image toLocation:location];
}

- (void)saveImageFromData:(LoShotData *)data {
    NSLog(@"saveImageFromData");
}

- (void)invalidateData:(LoShotData *)data {
    [_shotDataArray removeObject:data];
}

- (void)dataComplete: (LoShotData *) sender {
    [self saveImageFromData:sender];
}

@end
