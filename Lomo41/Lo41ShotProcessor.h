#import <Foundation/Foundation.h>

#import "LoShotSet.h"

@interface Lo41ShotProcessor : NSObject

- (id)initWithShotSet: (LoShotSet*) set;

- (void)processIndividualShots;

- (void)groupShots;

- (UIImage*)getProcessedGroupImage;

@end
