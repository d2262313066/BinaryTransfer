//
//  ViewController.m
//  NSData
//
//  Created by Dahao Jiang on 2018/4/18.
//  Copyright © 2018年 Dln. All rights reserved.
//

#import "ViewController.h"
#import <objc/runtime.h>
#import "ClientToSocket20000.h"
#import "DlnSocketUtils.h"

#define hostString @"192.168.1.92"

//TODO::开始验证了
//后面NSString这是运行时能获取到的C语言类型
NSString *const TYPE_UINT8 = @"TC"; //char 是1个字节，8位
NSString *const TYPE_UINT16 = @"TS"; //short是2个字节，16位
NSString *const TYPE_UINT32 = @"TI";
NSString *const TYPE_UINT64 = @"TQ";
NSString *const TYPE_STRING = @"T@\"NSString\"";
NSString * const TYPE_ARRAY   = @"T@\"NSArray\"";

@interface ViewController ()

@property (nonatomic, strong) NSMutableData *data;

@property (weak, nonatomic) IBOutlet UILabel *binaryLabel;
@property (weak, nonatomic) IBOutlet UITextField *uint_8Field;
@property (weak, nonatomic) IBOutlet UITextField *uint_16Field;
@property (weak, nonatomic) IBOutlet UITextField *uint_32Field;
@property (weak, nonatomic) IBOutlet UITextField *uint_64Field;
@property (weak, nonatomic) IBOutlet UITextField *messageField;
@property (weak, nonatomic) IBOutlet UILabel *descUint8;
@property (weak, nonatomic) IBOutlet UILabel *descUint16;
@property (weak, nonatomic) IBOutlet UILabel *descUint32;
@property (weak, nonatomic) IBOutlet UILabel *descMessage;



@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}



- (IBAction)sendAction:(id)sender {
    ClientToSocket20000 *model = [[ClientToSocket20000 alloc] init];
    model.typeUint8 = [_uint_8Field.text intValue]?:0;
    model.typeUint16 = [_uint_16Field.text intValue]?:0;
    model.typeUint32 = [_uint_32Field.text intValue]?:0;
    model.message = _messageField.text.length != 0 ? _messageField.text :@"nonnull";
    [self tranformBinary:model];
}

- (IBAction)unpack:(id)sender {
    [self Unpack];
}

//将包内容转换为二进制
- (void)tranformBinary:(id)obj {
    _data = [NSMutableData data];
    //包内容Data
    NSMutableData *contentData = [NSMutableData data];
    
    unsigned int numIVars; //成员变量个数
    Class class = NSClassFromString([NSString stringWithUTF8String:object_getClassName(obj)]);
    objc_property_t *propertys = class_copyPropertyList(class, &numIVars);
    NSString *className = [NSString stringWithUTF8String:object_getClassName(obj)];
    
    NSScanner *scanner = [NSScanner scannerWithString:className];
    [scanner scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:nil];
    int number; //服务号
    [scanner scanInt:&number];
    //服务号data
    NSData *serverData = [DlnSocketUtils byteFromUint32:number];


    NSString *type = nil;
    NSString *name = nil;
    for (int i = 0; i < numIVars; i ++) {
        objc_property_t property = propertys[i];
        
        name = [NSString stringWithUTF8String:property_getName(property)];
        NSLog(@"%d.name %@",i,name);
        type = [[[NSString stringWithUTF8String:property_getAttributes(property)] componentsSeparatedByString:@","] objectAtIndex:0];//获取成员变量数据类型
        NSLog(@"%d.type %@",i,type);
        
        id propertyValue = [obj valueForKey:name];
        NSLog(@"%d.propertyValue:%@\n",i,propertyValue);
        
        if ([type isEqualToString:TYPE_UINT8]) {
            uint8_t i = [propertyValue charValue]; //8位
            [contentData appendData:[DlnSocketUtils byteFromUint8:i]];
        } else if ([type isEqualToString:TYPE_UINT16]) {
            uint16_t i = [propertyValue shortValue];
            [contentData appendData:[DlnSocketUtils byteFromUint16:i]];
        } else if ([type isEqualToString:TYPE_UINT32]) {
            uint32_t i = [propertyValue intValue];
            [contentData appendData:[DlnSocketUtils byteFromUint32:i]];
        }else if ([type isEqualToString:TYPE_STRING]) {
            NSData *data = [(NSString *)propertyValue dataUsingEncoding:NSUTF8StringEncoding]; //utf8转data
            // 用2个字节拼接字符串的长度拼接在字符串data之前(知道获取的长度)
            [contentData appendData:[DlnSocketUtils byteFromUint16:data.length]];
            //然后拼接字符串
            [contentData appendData:data];
        } else {
            NSLog(@"RequestSpliceAttribute:未知类型");
            NSAssert(YES, @"RequestSpliceAttribute:未知类型");
        }
    }
    //获取包长
   NSData *packLengthdata = [DlnSocketUtils byteFromUint32:(int)contentData.length];
    [_data appendData:serverData]; //协议号
    [_data appendData:packLengthdata]; //包长
    [_data appendData:contentData]; //包内容
    
    _binaryLabel.text = [DlnSocketUtils hexStringFromData:_data];
    //拼接 服务号+包长+包内容
    
    free(propertys);
}

//解包
- (void)Unpack {
    unsigned int numIvars; //成员变量个数
    NSData *getServerData = [_data subdataWithRange:NSMakeRange(0, 4)]; //获取协议号
    NSData *getPackLengthdata = [_data subdataWithRange:NSMakeRange(4, 4)]; //获取包长
    
    /* demo  */
    uint32_t serverNum = [DlnSocketUtils uint32FromBytes:getServerData]; //20000
    NSString *serverName;

    int dataLenInt = CFSwapInt32BigToHost(*(int *)[getPackLengthdata bytes]);
    NSInteger lengthInteger = 0;
    lengthInteger = (NSInteger)dataLenInt;
    
    /** 服务端与客户端传输数据的时候用,防止粘包 */
    /*
    //因为协议号和长度字节占8位，所以大于8才是一个正确的数据包
    NSInteger complateDataLength = lengthInteger + 8; //算出一个包完整的长度(内容长度+头长度);
    while (_data.length > 8) {
        if (_data.length < complateDataLength) { //如果缓存中的数据长度小于包长度，则继续拼接
//            [_serverSocket readDataWithTimeout:-1 tag:0]; //服务端socket读取数据,这直接解包
//            break;
        } else {
            //截取完整数据包
            NSData *completeData = [_data subdataWithRange:NSMakeRange(0, complateDataLength)];
        }
    }
    */
    
    serverName = [NSString stringWithFormat:@"ClientToSocket%d",serverNum];//ClientToSocket20000

    id obj = [[NSClassFromString(serverName) alloc] init];
    
    NSData *contentData = [_data subdataWithRange:NSMakeRange(8, dataLenInt)];
    
    objc_property_t *propertys = class_copyPropertyList(NSClassFromString(serverName), &numIvars);

    NSString *type = nil;
    NSString *name = nil;

    int subIndex = 0;
    for (int i = 0; i < numIvars; i++) {
        objc_property_t thisProperty = propertys[i];

        name = [NSString stringWithUTF8String:property_getName(thisProperty)];
        NSLog(@"%d.name:%@",i,name);
        type = [[[NSString stringWithUTF8String:property_getAttributes(thisProperty)] componentsSeparatedByString:@","] objectAtIndex:0]; //获取成员变量的数据类型
        NSLog(@"%d.type:%@",i,type);

        id propertyValue = [obj valueForKey:[(NSString *)name substringFromIndex:0]];
        NSLog(@"%d.propertyValue:%@",i,propertyValue);

        NSLog(@"\n");
        if ([type isEqualToString:TYPE_UINT8]) {
            NSData *data = [contentData subdataWithRange:NSMakeRange(subIndex, 1)];
            uint8_t u8 = [DlnSocketUtils uint8FromBytes:data];
            [obj setValue:@(u8) forKey:name];
            _descUint8.text = [NSString stringWithFormat:@"%@",[obj valueForKey:name]];
            subIndex += 1;
        }else if([type isEqualToString:TYPE_UINT16]){
            NSData *data = [contentData subdataWithRange:NSMakeRange(subIndex, 2)];
            uint16_t u16 = [DlnSocketUtils uint16FromBytes:data];
            [obj setValue:@(u16) forKey:name];
            _descUint16.text = [NSString stringWithFormat:@"%@",[obj valueForKey:name]];
            subIndex += 2;
        }else if([type isEqualToString:TYPE_UINT32]){
            NSData *data = [contentData subdataWithRange:NSMakeRange(subIndex, 4)];
            uint32_t u32 = [DlnSocketUtils uint32FromBytes:data];
            [obj setValue:@(u32) forKey:name];
            _descUint32.text = [NSString stringWithFormat:@"%@",[obj valueForKey:name]];
            subIndex += 4;
        }else if([type isEqualToString:TYPE_STRING]){
            
            NSData *stringLengthData = [contentData subdataWithRange:NSMakeRange(subIndex, 2)];//获取2个字节的字符串长度
            subIndex += 2;
            unsigned short stringDataLength = [DlnSocketUtils uint16FromBytes:stringLengthData];
            
            NSData *stringData = [contentData subdataWithRange:NSMakeRange(subIndex, stringDataLength)];
            NSString *string = [[NSString alloc] initWithData:stringData encoding:NSUTF8StringEncoding];
            [obj setValue:string forKey:name];
            _descMessage.text = [obj valueForKey:name];
            
            subIndex += stringDataLength;
        }else {
            NSLog(@"RequestSpliceAttribute:未知类型");
            NSAssert(YES, @"RequestSpliceAttribute:未知类型");
        }
    }
    

    // hy: 记得释放C语言的结构体指针
    free(propertys);
}


@end

