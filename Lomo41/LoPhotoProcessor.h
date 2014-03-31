#import <Foundation/Foundation.h>

#import "LoShotData.h"

@interface LoPhotoProcessor : NSObject <LoShotDataDelegate>

@property (nonatomic, readonly, getter = getCount) NSUInteger count;

- (LoShotData *)newShotHandle;
- (void)processImage:(UIImage *)image
          atLocation:(PaneLocation)location
            withData:(LoShotData *)data;
- (void)invalidateData:(LoShotData *)data;
- (void)dataComplete: (LoShotData *) sender;
@end
