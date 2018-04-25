//
//  DlnSocketUtils.m
//  NSData
//
//  Created by Dahao Jiang on 2018/4/20.
//  Copyright © 2018年 Dln. All rights reserved.
//

#import "DlnSocketUtils.h"

@implementation DlnSocketUtils
/**
 *  反转字节序列
 *
 *  @param srcData 原始字节NSData
 *
 *  @return 反转序列后字节NSData
 */
+ (NSData *)dataWithReverse:(NSData *)srcData {
    NSUInteger byteCount = srcData.length;
    NSMutableData *dstData = [[NSMutableData alloc] initWithData:srcData];
    NSUInteger halfLength = byteCount / 2;
    for (NSInteger i = 0; i < halfLength; i ++) {
        NSRange begin = NSMakeRange(i, 1);
        NSRange end = NSMakeRange(byteCount - i - 1, 1);
        NSData *beginData = [srcData subdataWithRange:begin];
        NSData *endData = [srcData subdataWithRange:end];
        [dstData replaceBytesInRange:begin withBytes:endData.bytes];
        [dstData replaceBytesInRange:end withBytes:beginData.bytes];
    }
    return dstData;
}

+ (NSData *)byteFromUint8:(uint8_t)val {
    NSMutableData *valData = [[NSMutableData alloc] init];
    
    //unsigned char valChar[1],1byte -> 8 bit(1111 1111),即最大0xff
    unsigned char valChar[1];
    
    for (int i = 0; i < 1; i ++) {
        valChar[i] = val >> 8 * i;
    }
    
    [valData appendBytes:valChar length:1];
    
    return [self dataWithReverse:valData];
}

+(NSData *)byteFromUint16:(uint16_t)val {
    NSMutableData *valData = [[NSMutableData alloc] init];
    unsigned char valChar[2];

    for (int i = 0; i < 2; i ++) {
        valChar[i] = val >> 8 * i;
    }
    
    [valData appendBytes:valChar length:2];
    
    
    return [self dataWithReverse:valData];
}

+(NSData *)byteFromUint32:(uint32_t)val {
    NSMutableData *valData = [[NSMutableData alloc] init];
    unsigned char valChar[4];

    for (int i = 0; i < 4; i ++) {
        valChar[i] = val >> 8 * i;
    }
    
    [valData appendBytes:valChar length:4];
    
    return [self dataWithReverse:valData];
}

+(NSData *)byteFromUint64:(uint64_t)val {
    NSMutableData *valData = [[NSMutableData alloc] init];
    unsigned char valChar[8];
    for (int i = 0; i < 8; i ++) {
        valChar[i] = val >> 8 * i;
    }
    [valData appendBytes:valChar length:8];
    
    return [self dataWithReverse:valData];
    /*
     原up的方法,更易看懂，以上类推
     valChar[0] = 0xff & val;
     valChar[1] = (0xff00 & val) >> 8;
     valChar[2] = (0xff0000 & val) >> 16;
     valChar[3] = (0xff000000 & val) >> 24;
     valChar[4] = (0xff00000000 & val) >> 32;
     valChar[5] = (0xff0000000000 & val) >> 40;
     valChar[6] = (0xff000000000000 & val) >> 48;
     valChar[7] = (0xff00000000000000 & val) >> 56;
     */
}

+(NSData *)bytesFromValue:(NSInteger)value byteCount:(int)byteCount {
    NSAssert(value <= 4294967295, @"bytesFromValue:(max value is 4294967295)");
    NSAssert(byteCount <= 4, @"bytesFromValue:(byte count is too long)");
    
    NSMutableData *valData = [[NSMutableData alloc] init];
    NSUInteger tempVal = value;
    int offset = 0;
    while (offset < byteCount) {
        unsigned char valChar = 0xff & tempVal;
        [valData appendBytes:&valChar length:1];
        tempVal = tempVal >> 8;
        offset ++;
    }
    return valData;
}

+(NSData *)bytesFromValue:(NSInteger)value byteCount:(int)byteCount reverse:(BOOL)reverse {
    NSData *tempData = [self bytesFromValue:value byteCount:byteCount];
    if (reverse) {
        return tempData;
    }
    return [self dataWithReverse:tempData];
}

+(uint8_t)uint8FromBytes:(NSData *)fData {
    NSAssert(fData.length == 1, @"uint8FromBytes:(data length != 1)");
    NSData *data = fData;
    uint8_t val = 0;
    [data getBytes:&val length:1];
    return val;
}

+(uint16_t)uint16FromBytes:(NSData *)fdata {
    NSAssert(fdata.length == 2, @"uint16FromBytes:(data length != 2)");
    NSData *data = [self dataWithReverse:fdata];
    uint16_t dstVal = 0;
    for (int i = 0; i < 2; i ++) {
        uint16_t val = 0;
        [data getBytes:&val range:NSMakeRange(i, 1)];
        dstVal += val << 8 * i;
    }
    return dstVal;

}

+(uint32_t)uint32FromBytes:(NSData *)fdata {
    NSAssert(fdata.length == 4, @"uint16FromBytes:(data length != 2)");
    NSData *data = [self dataWithReverse:fdata];
    uint32_t dstVal = 0;
    for (int i = 0; i < 4; i ++) {
        uint32_t val = 0;
        [data getBytes:&val range:NSMakeRange(i, 1)];
        dstVal += val << 8 * i;
    }
    return dstVal;
    /*
     原up的方法,更易看懂，以上类推
     uint32_t val0 = 0;
     uint32_t val1 = 0;
     uint32_t val2 = 0;
     uint32_t val3 = 0;
     [data getBytes:&val0 range:NSMakeRange(0, 1)];
     [data getBytes:&val1 range:NSMakeRange(1, 1)];
     [data getBytes:&val2 range:NSMakeRange(2, 1)];
     [data getBytes:&val3 range:NSMakeRange(3, 1)];
     
     uint32_t dstVal = (val0 & 0xff) + ((val1 << 8) & 0xff00) + ((val1 << 16) & 0xff0000) + ((val1 << 24) & 0xff000000);
     */
}

+(NSInteger)valueFromBytes:(NSData *)data {
    NSAssert(data.length <= 4, @"valueFromBytes:(data is too long)");
    
    NSUInteger dataLen = data.length;
    NSUInteger value = 0;
    int offset = 0;
    while (offset < dataLen) {
        uint32_t tempVal = 0;
        [data getBytes:&tempVal range:NSMakeRange(offset, 1)];
        value += (tempVal << (8 * offset));
        offset ++;
    }
    return value;
}

+(NSInteger)valuefromBytes:(NSData *)data reverse:(BOOL)reverse {
    NSData *tempData = data;
    if (reverse) {
        tempData = [self dataWithReverse:tempData];
    }
    return [self valueFromBytes:tempData];
}

/** 16进制字符串转换为data。24211D3498FF62AF  -->  <24211D34 98FF62AF>  */
+(NSData *)dataFromHexString:(NSString *)hexString {
    NSAssert((hexString.length > 0 && (hexString.length % 2 == 0)), @"dataFromHexString mod2 != 0");
    NSMutableData *data = [[NSMutableData alloc] init];
    for (NSUInteger i = 0; i < hexString.length; i += 2) {
        NSRange tempRange = NSMakeRange(i, 2);
        NSString *tempStr = [hexString substringWithRange:tempRange];
        NSScanner *scanner = [NSScanner scannerWithString:tempStr];
        unsigned int tempIntValue;
        [scanner scanHexInt:&tempIntValue];
        [data appendBytes:&tempIntValue length:1];
    }
    return data;
}

+(NSString *)hexStringFromData:(NSData *)data {
    NSAssert(data.length > 0, @"data.length <= 0");
    NSMutableString *hexString = [[NSMutableString alloc] init];
    const Byte *bytes = data.bytes;
    for (NSUInteger i = 0; i < data.length; i ++) {
        Byte value = bytes[i];
        Byte high = (value & 0xf0) >> 4;
        Byte low = value & 0x0f;
        [hexString appendFormat:@"%x%x",high,low];
    }
    return hexString;
}

//..
+ (NSString *)asciiStringFromHexString:(NSString *)hexString
{
    NSMutableString *asciiString = [[NSMutableString alloc] init];
    const char *bytes = [hexString UTF8String];
    for (NSUInteger i=0; i<hexString.length; i++) {
        [asciiString appendFormat:@"%0.2X", bytes[i]];
    }
    return asciiString;
}

+ (NSString *)hexStringFromASCIIString:(NSString *)asciiString
{
    NSMutableString *hexString = [[NSMutableString alloc] init];
    const char *asciiChars = [asciiString UTF8String];
    for (NSUInteger i=0; i<asciiString.length; i+=2) {
        char hexChar = '\0';
        
        //high
        if (asciiChars[i] >= '0' && asciiChars[i] <= '9') {
            hexChar = (asciiChars[i] - '0') << 4;
        } else if (asciiChars[i] >= 'a' && asciiChars[i] <= 'z') {
            hexChar = (asciiChars[i] - 'a' + 10) << 4;
        } else if (asciiChars[i] >= 'A' && asciiChars[i] <= 'Z') {
            hexChar = (asciiChars[i] - 'A' + 10) << 4;
        }//if
        
        //low
        if (asciiChars[i+1] >= '0' && asciiChars[i+1] <= '9') {
            hexChar += asciiChars[i+1] - '0';
        } else if (asciiChars[i+1] >= 'a' && asciiChars[i+1] <= 'z') {
            hexChar += asciiChars[i+1] - 'a' + 10;
        } else if (asciiChars[i+1] >= 'A' && asciiChars[i+1] <= 'Z') {
            hexChar += asciiChars[i+1] - 'A' + 10;
        }//if
        
        [hexString appendFormat:@"%c", hexChar];
    }
    return hexString;
}


@end
