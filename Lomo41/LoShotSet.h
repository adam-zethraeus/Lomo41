@interface LoShotSet : NSObject

@property (nonatomic, readonly, getter = getCount) NSUInteger count;
@property (nonatomic, readonly, getter = getShotsArray) NSArray *shotsArray;
@property (nonatomic) UIDeviceOrientation orientation;

// Init with intended size. Default init is 4.
- (id)initForSize: (NSUInteger) size;

// Be aware, addShot will fail silently if you attempt to add more shots
// than the set was specified to be able to contain.
- (void)addShot:(UIImage *)image;

@end
