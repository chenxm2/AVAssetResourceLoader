//
//  TTDownloadSegment.m
//  aaa
//
//  Created by xianmingchen on 15/7/9.
//  Copyright (c) 2015年 kumapower. All rights reserved.
//

#import "TTDownloadSegment.h"
#import "AFHTTPRequestOperationManager.h"
#import "AFHTTPRequestOperation.h"

@interface TTDownloadSegment ()
@property (nonatomic, assign) unsigned long long offset;
@property (nonatomic, assign) unsigned long long length;
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) AFHTTPRequestOperation *operation;
@property (nonatomic, strong) AFHTTPRequestOperationManager *manager;
@end

@implementation TTDownloadSegment
- (id)initWithURL:(NSURL *)url offset:(unsigned long long)offset length:(unsigned long long)length manager:(AFHTTPRequestOperationManager *)manager
{
    self = [super init];
    if (self)
    {
        self.url = url;
        self.offset = offset;
        self.length = length;
        self.manager = manager;
        
        [self _createOperation];
        
    }
    return self;
}

- (void)_createOperation
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.url];
    
    [request setValue:[NSString stringWithFormat:@"bytes=%lld-%lld", self.offset, self.offset + self.length - 1]  forHTTPHeaderField:@"Range"];
    
   self.operation = [self.manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
       [self.delegate didSegmentFinished:self];
       
    } failure:^(AFHTTPRequestOperation *operation, NSError *error){
        NSLog(@"_createOperation Fail:%@", error);
    }];

}
@end
