//
//  BePeripheralViewController.m
//  BleDemo
//
//  Created by ZTELiuyw on 15/9/7.
//  Copyright (c) 2015年 liuyanwei. All rights reserved.
//

#import "BePeripheralViewController.h"


static NSString *const ServiceUUID1 =  @"204CA5C5-DE02-4B43-A9FF-FA69270BB9E5";
static NSString *const readwriteCharacteristicUUID =  @"FFFF";

static unsigned char  const s_hender = 0xBA;
static unsigned char  const s_hender2 = 0x5B;

static unsigned char const s_version = 1; //版本号
static unsigned char const s_command = 2;//主命令
static unsigned char const s_commandWeight = 2;//获取一条重量数据
static unsigned char const s_commandCount = 3;//获取同步数据总条数
static unsigned char const s_commandDel = 4;//删除所有重量数据
static unsigned char const s_commandTime = 1;//删除所有重量数据

static unsigned char const s_dataLen = 16;


@interface BePeripheralViewController()
<
UITableViewDelegate
, UITableViewDataSource
>

@end

@implementation BePeripheralViewController{
    CBPeripheralManager *peripheralManager;
    //定时器
    NSTimer *timer;
    //添加成功的service数量
    int serviceNum;
    
    UITableView     *_tableView;
    NSMutableArray  *_logArray;
   
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"清除" style:UIBarButtonItemStylePlain target:self action:@selector(clearLog:)];
    
    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.rowHeight = 30;
//    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [self.view addSubview:_tableView];
    
    _logArray = [NSMutableArray array];
    
    /*
     和CBCentralManager类似，蓝牙设备打开需要一定时间，打开成功后会进入委托方法
     - (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral;
     模拟器永远也不会得CBPeripheralManagerStatePoweredOn状态
     */
    peripheralManager = [[CBPeripheralManager alloc]initWithDelegate:self queue:nil];
   
    //页面样式
    [self.view setBackgroundColor:[UIColor whiteColor]];
    [self showLog:@"正在打开设备"];

}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [peripheralManager stopAdvertising];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    _tableView.frame = self.view.bounds;
}


//配置bluetooch的
-(void)setUp{
    /*
     可读写的characteristics
     properties：CBCharacteristicPropertyWrite | CBCharacteristicPropertyRead | CBCharacteristicPropertyNotify
     permissions CBAttributePermissionsReadable | CBAttributePermissionsWriteable
     */
    CBMutableCharacteristic *readwriteCharacteristic = [[CBMutableCharacteristic alloc]initWithType:[CBUUID UUIDWithString:readwriteCharacteristicUUID]
                                                                                         properties:CBCharacteristicPropertyWrite | CBCharacteristicPropertyRead | CBCharacteristicPropertyNotify value:nil
                                                                                        permissions:CBAttributePermissionsReadable | CBAttributePermissionsWriteable];
    

    //service1初始化并加入两个characteristics
    CBMutableService *service1 = [[CBMutableService alloc]initWithType:[CBUUID UUIDWithString:ServiceUUID1] primary:YES];
    NSLog(@"%@",service1.UUID);
    
    [service1 setCharacteristics:@[readwriteCharacteristic]];
    [peripheralManager addService:service1];
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_logArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 30)];
        label.font = [UIFont systemFontOfSize:11];
        label.numberOfLines = 2;
        [cell.contentView addSubview:label];
        label.tag = 1000;
    };
    
    UILabel *lable = [cell.contentView viewWithTag:1000];
    lable.text = _logArray[indexPath.row];
    
    return cell;
}


#pragma  mark -- CBPeripheralManagerDelegate

//peripheralManager状态改变
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral{
    switch (peripheral.state) {
            //在这里判断蓝牙设别的状态  当开启了则可调用  setUp方法(自定义)
        case CBPeripheralManagerStatePoweredOn:
            NSLog(@"powered on");
            
            [self showLog:[NSString stringWithFormat:@"设备名%@已经打开，可以使用center进行连接",self.peripheralName]];
            [self setUp];
            break;
        case CBPeripheralManagerStatePoweredOff:
            NSLog(@"powered off");
            [self showLog:@"powered off"];
            break;
            
        default:
            break;
    }
}

//perihpheral添加了service
- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error{
    [peripheralManager startAdvertising:@{
                                          CBAdvertisementDataServiceUUIDsKey : @[service.UUID],
                                          CBAdvertisementDataLocalNameKey : self.peripheralName
                                          }
     ];
}

//peripheral开始发送advertising
- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error{
    [self showLog:(@"in peripheralManagerDidStartAdvertisiong")];
}

//订阅characteristics
-(void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic{
    [self showLog:[NSString stringWithFormat:@"订阅了 %@的数据",characteristic.UUID]];
    //每秒执行一次给主设备发送一个当前时间的秒数
//    timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(sendData:) userInfo:characteristic  repeats:YES];
}

//取消订阅characteristics
-(void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic{
    
    [self showLog:[NSString stringWithFormat:@"取消订阅 %@的数据",characteristic.UUID]];
    //取消回应
//    [timer invalidate];
}

//发送数据，发送当前时间的秒数
-(BOOL)sendCountData:(CBMutableCharacteristic *)characteristic {
    
    //协议头
    NSMutableData *requestData = [NSMutableData dataWithCapacity:s_dataLen];
    
    NSData* dataHeader = [NSData dataWithBytes:&s_hender length:1];
    [requestData appendData:dataHeader];
    
    dataHeader = [NSData dataWithBytes:&s_hender2 length:1];
    [requestData appendData:dataHeader];
    
    //数据长度
    NSData *dataLen = [NSData dataWithBytes:&s_dataLen length:1];
    [requestData appendData:dataLen];
    
    //序列号
    unsigned char serialnum = 1;
    NSData *dataSerialnum = [NSData dataWithBytes:&serialnum length:1];
    [requestData appendData:dataSerialnum];
    
    //版本号
    NSData *dataVer = [NSData dataWithBytes:&s_version length:1];
    [requestData appendData:dataVer];
    
    //主命令
    NSData *dataCommand = [NSData dataWithBytes:&s_command length:1];
    [requestData appendData:dataCommand];
    
    //子命令
    NSData *dataCommandCount = [NSData dataWithBytes:&s_commandCount length:1];
    [requestData appendData:dataCommandCount];
    
    //数据
    unsigned char count = 12;
    NSData *data = [NSData dataWithBytes:&count length:1];
    [requestData appendData:data];

    unsigned char fillVal = 0;
    NSData *fillData = [NSData dataWithBytes:&fillVal length:1];
    
    for (int i = 0; i < 7; ++i) {
        [requestData appendData:fillData];
    }
    
    unsigned char crc = [self CRC8:(unsigned char*)(requestData.bytes)
                               len:[requestData length]];
    
    [requestData appendBytes:&crc length:1];
    
    [self showLog:[NSString stringWithFormat:@"返回数据条数：%@", requestData]];
    return  [peripheralManager updateValue:requestData
                         forCharacteristic:characteristic
                      onSubscribedCentrals:nil];
    
}

-(BOOL)sendWeightData:(CBMutableCharacteristic *)characteristic index:(unsigned char)index {
    
    //协议头
    NSMutableData *requestData = [NSMutableData dataWithCapacity:s_dataLen];
    
    NSData* dataHeader = [NSData dataWithBytes:&s_hender length:1];
    [requestData appendData:dataHeader];
    
    dataHeader = [NSData dataWithBytes:&s_hender2 length:1];
    [requestData appendData:dataHeader];
    
    //数据长度
    NSData *dataLen = [NSData dataWithBytes:&s_dataLen length:1];
    [requestData appendData:dataLen];
    
    //序列号
    unsigned char serialnum = 1;
    NSData *dataSerialnum = [NSData dataWithBytes:&serialnum length:1];
    [requestData appendData:dataSerialnum];
    
    //版本号
    NSData *dataVer = [NSData dataWithBytes:&s_version length:1];
    [requestData appendData:dataVer];
    
    //主命令
    NSData *dataCommand = [NSData dataWithBytes:&s_command length:1];
    [requestData appendData:dataCommand];
    
    //子命令
    NSData *dataCommandCount = [NSData dataWithBytes:&s_commandWeight length:1];
    [requestData appendData:dataCommandCount];
    
    //数据1 当前索引
    NSData *data = [NSData dataWithBytes:&index length:1];
    [requestData appendData:data];
    
    //数据2 年
    unsigned char year = 16;
    data = [NSData dataWithBytes:&year length:1];
    [requestData appendData:data];
    
    //数据3 月
    unsigned char month = 5;
    data = [NSData dataWithBytes:&month length:1];
    [requestData appendData:data];
    
    //数据4 日
    unsigned char day = [self getDay:[NSDate date]];
    data = [NSData dataWithBytes:&day length:1];
    [requestData appendData:data];
    
    //数据5 小时
    unsigned char hour = [self getHour:[NSDate date]];
    data = [NSData dataWithBytes:&hour length:1];
    [requestData appendData:data];
    
    //数据6 分
    unsigned char minutes = index + 10;
    data = [NSData dataWithBytes:&minutes length:1];
    [requestData appendData:data];
    
    //数据7 8 重量
    int16_t weight =  hour * 10 + index * 10;
    unsigned short weightVal = NSSwapShort(weight);
    data = [NSData dataWithBytes:&weightVal length:2];
    [requestData appendData:data];
    
    
    unsigned char crc = [self CRC8:(unsigned char*)(requestData.bytes)
                                           len:[requestData length]];
    
    [requestData appendBytes:&crc length:1];
    
    [self showLog:[NSString stringWithFormat:@"返回重量数据：%@, index:%d", requestData, index]];

    
    return  [peripheralManager updateValue:requestData
                         forCharacteristic:characteristic
                      onSubscribedCentrals:nil];
    
    
    
}

//发送数据，发送当前时间的秒数
-(BOOL)sendDeleteData:(CBMutableCharacteristic *)characteristic {
    
    //协议头
    NSMutableData *requestData = [NSMutableData dataWithCapacity:s_dataLen];
    
    NSData* dataHeader = [NSData dataWithBytes:&s_hender length:1];
    [requestData appendData:dataHeader];
    
    dataHeader = [NSData dataWithBytes:&s_hender2 length:1];
    [requestData appendData:dataHeader];
    
    //数据长度
    NSData *dataLen = [NSData dataWithBytes:&s_dataLen length:1];
    [requestData appendData:dataLen];
    
    //序列号
    unsigned char serialnum = 1;
    NSData *dataSerialnum = [NSData dataWithBytes:&serialnum length:1];
    [requestData appendData:dataSerialnum];
    
    //版本号
    NSData *dataVer = [NSData dataWithBytes:&s_version length:1];
    [requestData appendData:dataVer];
    
    //主命令
    NSData *dataCommand = [NSData dataWithBytes:&s_command length:1];
    [requestData appendData:dataCommand];
    
    //子命令
    NSData *dataCommandCount = [NSData dataWithBytes:&s_commandDel length:1];
    [requestData appendData:dataCommandCount];
    
    //数据
    unsigned char fillVal = 0;
    NSData *fillData = [NSData dataWithBytes:&fillVal length:1];
    
    for (int i = 0; i < 8; ++i) {
        [requestData appendData:fillData];
    }
    
    unsigned char crc = [self CRC8:(unsigned char*)(requestData.bytes)
                               len:[requestData length]];
    
    [requestData appendBytes:&crc length:1];
    
    [self showLog:[NSString stringWithFormat:@"返回删除数据响应结果：%@", requestData]];
    return  [peripheralManager updateValue:requestData
                         forCharacteristic:characteristic
                      onSubscribedCentrals:nil];
    
}

//发送数据，发送当前时间的秒数
-(BOOL)sendTimeData:(CBMutableCharacteristic *)characteristic {
    
    //协议头
    NSMutableData *requestData = [NSMutableData dataWithCapacity:s_dataLen];
    
    NSData* dataHeader = [NSData dataWithBytes:&s_hender length:1];
    [requestData appendData:dataHeader];
    
    dataHeader = [NSData dataWithBytes:&s_hender2 length:1];
    [requestData appendData:dataHeader];
    
    //数据长度
    NSData *dataLen = [NSData dataWithBytes:&s_dataLen length:1];
    [requestData appendData:dataLen];
    
    //序列号
    unsigned char serialnum = 1;
    NSData *dataSerialnum = [NSData dataWithBytes:&serialnum length:1];
    [requestData appendData:dataSerialnum];
    
    //版本号
    NSData *dataVer = [NSData dataWithBytes:&s_version length:1];
    [requestData appendData:dataVer];
    
    //主命令
    NSData *dataCommand = [NSData dataWithBytes:&s_command length:1];
    [requestData appendData:dataCommand];
    
    //子命令
    NSData *dataCommandCount = [NSData dataWithBytes:&s_commandTime length:1];
    [requestData appendData:dataCommandCount];
    
    //数据
    unsigned char fillVal = 0;
    NSData *fillData = [NSData dataWithBytes:&fillVal length:1];
    
    for (int i = 0; i < 8; ++i) {
        [requestData appendData:fillData];
    }
    
    unsigned char crc = [self CRC8:(unsigned char*)(requestData.bytes)
                               len:[requestData length]];
    
    [requestData appendBytes:&crc length:1];
    
    [self showLog:[NSString stringWithFormat:@"返回设置时间响应结果：%@", requestData]];
    return  [peripheralManager updateValue:requestData
                         forCharacteristic:characteristic
                      onSubscribedCentrals:nil];
    
}


//读characteristics请求
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request{
    NSLog(@"didReceiveReadRequest");
    //判断是否有读数据的权限
    if (request.characteristic.properties & CBCharacteristicPropertyRead) {
        
        //对请求作出成功响应
        [peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
        
        [self showLog:[NSString stringWithFormat:@"读请求: %@", request.characteristic.value]];

    }else{
        [peripheralManager respondToRequest:request withResult:CBATTErrorWriteNotPermitted];
    }
}


//写characteristics请求
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray *)requests{
    NSLog(@"didReceiveWriteRequests");
    CBATTRequest *request = requests[0];
    
    //判断是否有写数据的权限
    if (request.characteristic.properties & CBCharacteristicPropertyWrite) {
        //需要转换成CBMutableCharacteristic对象才能进行写值
        CBMutableCharacteristic *c =(CBMutableCharacteristic *)request.characteristic;

        [peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
        
        [self showLog:[NSString stringWithFormat:@"写请求: %@", request.value]];
        
        NSData *data = request.value;
        if ([data length] == s_dataLen) {
            
            unsigned char subcommand = 0;
            [data getBytes:&subcommand range:NSMakeRange(6, 1)];
            
            if (subcommand == s_commandCount) {
                
                [self showLog:[NSString stringWithFormat:@"请求协议: %@", @"总数据条数"]];

                [self sendCountData:c];

            } else if (subcommand == s_commandWeight) {
                
                unsigned char index = 0;
                [data getBytes:&index range:NSMakeRange(7, 1)];
                
                [self showLog:[NSString stringWithFormat:@"请求协议: 请求第%d条重量", index]];

                [self sendWeightData:c index:index];
            } else if (subcommand == s_commandTime) {
                
                [self showLog:[NSString stringWithFormat:@"请求协议: 设置时间"]];
                [self sendTimeData:c];
                
            } else if (subcommand == s_commandDel) {
                
                [self showLog:[NSString stringWithFormat:@"请求协议: 删除所有数据"]];
                [self sendDeleteData:c];
            }
            
        }
        
    }else{
        [peripheralManager respondToRequest:request withResult:CBATTErrorWriteNotPermitted];
    }
    
    
}

//
- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral{
    NSLog(@"peripheralManagerIsReadyToUpdateSubscribers");
    
}

- (void)clearLog:(id)sender
{
    [_logArray removeAllObjects];
    [_tableView reloadData];
}

- (void)showLog:(NSString *)log
{
    if ([log length] > 0) {
        [_logArray addObject:log];
        [_tableView reloadData];
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[_logArray count] - 1 inSection:0];
        [_tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionNone animated:NO];
    }
}

//获取NSDate的日期部分
-(unsigned char)getDay:(NSDate *)date{
    NSDateFormatter *formatter=[[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"dd"];
    NSString *dayStr=[formatter stringFromDate:date];
    
    return [dayStr intValue];
}
//获取NSDate的小时部分
-(NSInteger)getHour:(NSDate *)date{
    NSDateFormatter *formatter=[[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH"];
    NSString *hourStr=[formatter stringFromDate:date];
    
    return [hourStr intValue];
}
//获取NSDate的分钟部分
-(NSInteger)getMinute:(NSDate *)date{
    NSDateFormatter *formatter=[[NSDateFormatter alloc] init];
    [formatter dateFromString:@"mm"];
    NSString *minuteStr=[formatter stringFromDate:date];
    
    return [minuteStr intValue];
}

- (unsigned char)CRC8:(unsigned char *)ptr len:(unsigned char)len
{
    unsigned char crc;
    unsigned char i;
    crc = 0;
    
    while (len--) {
        
        crc ^= *ptr++;
        for(i = 0; i < 8; i++) {
            if(crc & 0x01) {
                crc = (crc >> 1) ^ 0x8C;
            } else {
                crc >>= 1;
            }
        }
    }
    
    return crc;
}

@end