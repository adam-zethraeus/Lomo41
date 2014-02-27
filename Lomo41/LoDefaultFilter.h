//
//  LoDefaultFilter.h
//  Lomo41
//
//  Created by Adam Zethraeus on 2/26/14.
//  Copyright (c) 2014 Very Nice Co. All rights reserved.
//

#import "GPUImageFilterGroup.h"

 @class GPUImagePicture;

@interface LoDefaultFilter : GPUImageFilterGroup {
    GPUImagePicture *lookupImageSource;
}

@end
