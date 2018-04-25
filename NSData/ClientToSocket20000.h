//
//  ClientToSocket20000.h
//  NSData
//
//  Created by Dahao Jiang on 2018/4/20.
//  Copyright © 2018年 Dln. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ClientToSocket20000 : NSObject

@property (nonatomic, assign) uint8_t  typeUint8;
@property (nonatomic, assign) uint16_t typeUint16;
@property (nonatomic, assign) uint32_t typeUint32;
@property (nonatomic, strong) NSString *message;

@end
