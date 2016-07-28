//
//  ViewController.m
//  MultipeerConnectivity
//
//  Created by lihongfeng on 16/7/22.
//  Copyright © 2016年 wanglei. All rights reserved.
//

#import "ViewController.h"
#import <MultipeerConnectivity/MultipeerConnectivity.h>

#define SERVICE_TYPE @"serviceType"

@interface ViewController ()<MCBrowserViewControllerDelegate, MCSessionDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (nonatomic, strong) MCSession *session;
@property (nonatomic, strong) MCAdvertiserAssistant *assistant;
@property (nonatomic, strong) MCPeerID *peerID;
@property (nonatomic, assign) MCSessionState state;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.state = MCSessionStateNotConnected;
    
    self.session = [[MCSession alloc] initWithPeer:[[MCPeerID alloc] initWithDisplayName:[UIDevice currentDevice].name]];
    self.session.delegate = self;
    
}

//连接设备
- (IBAction)connect:(id)sender {
    if (self.assistant != nil) {
        MCBrowserViewController *brower = [[MCBrowserViewController alloc] initWithServiceType:SERVICE_TYPE session:self.session];
        brower.delegate = self;
        [self presentViewController:brower animated:YES completion:nil];
    }else{
        NSLog(@"设备无法被扫描到.");
        UIAlertController *alertCtr = [UIAlertController alertControllerWithTitle:@"请打开\"设备可被发现\"!" message:nil preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *acition = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [alertCtr dismissViewControllerAnimated:YES completion:nil];
        }];
        [alertCtr addAction:acition];
        [self presentViewController:alertCtr animated:YES completion:nil];
    }
}

//选择图片
- (IBAction)selectImg:(id)sender {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary | UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    [self presentViewController:picker animated:YES completion:nil];
}

//发送图片
- (IBAction)sendImg:(id)sender {
    if (self.imageView.image != nil && self.assistant != nil && self.peerID != nil && self.state == MCSessionStateConnected) {
        [self.session sendData:UIImagePNGRepresentation(self.imageView.image) toPeers:@[self.peerID] withMode:MCSessionSendDataUnreliable error:nil];
    }else{
        
        UIAlertController *alertCtr;
        UIAlertAction *acition = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [alertCtr dismissViewControllerAnimated:YES completion:nil];
        }];
        
        if (self.assistant == nil) {
            NSLog(@"请打开\"设备可被发现\"!");
            alertCtr = [UIAlertController alertControllerWithTitle:@"请打开\"设备可被发现\"!" message:nil preferredStyle:UIAlertControllerStyleAlert];
            [alertCtr addAction:acition];
            [self presentViewController:alertCtr animated:YES completion:nil];
            return;
        }
        if (self.state != MCSessionStateConnected) {
            NSLog(@"设备还未连接蓝牙设备.");
            alertCtr = [UIAlertController alertControllerWithTitle:@"设备还未连接蓝牙设备." message:nil preferredStyle:UIAlertControllerStyleAlert];
            [alertCtr addAction:acition];
            [self presentViewController:alertCtr animated:YES completion:nil];
            return;
        }
        if (self.imageView.image == nil) {
            NSLog(@"请选择要发送的图片.");
            alertCtr = [UIAlertController alertControllerWithTitle:@"请选择要发送的图片." message:nil preferredStyle:UIAlertControllerStyleAlert];
            [alertCtr addAction:acition];
            [self presentViewController:alertCtr animated:YES completion:nil];
            return;
        }
        
    }
}

//设备是否能被扫描到
- (IBAction)switchStatus:(id)sender {
    UISwitch *s = (UISwitch *)sender;
    if (s.on) {
        self.statusLabel.textColor = [UIColor blackColor];
        MCAdvertiserAssistant *assistant = [[MCAdvertiserAssistant alloc] initWithServiceType:SERVICE_TYPE
                                                                                discoveryInfo:nil
                                                                                      session:self.session];
        self.assistant = assistant;
        [self.assistant start];
        
    }else{
        self.statusLabel.textColor = [UIColor lightGrayColor];
        [self.assistant stop];
        self.assistant = nil;
    }
    
}

#pragma mark - MCBrowserViewControllerDelegate
- (void)browserViewControllerDidFinish:(MCBrowserViewController *)browserViewController{
    [browserViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)browserViewControllerWasCancelled:(MCBrowserViewController *)browserViewController{
    [browserViewController dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)browserViewController:(MCBrowserViewController *)browserViewController
      shouldPresentNearbyPeer:(MCPeerID *)peerID
            withDiscoveryInfo:(nullable NSDictionary<NSString *, NSString *> *)info{
    NSLog(@"---已发现设备---peerID: %@", peerID);
    return YES;
}

#pragma mark - MCSessionDelegate
// Remote peer changed state.
- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state{
    self.peerID = peerID;
    self.state = state;
    switch (state) {
        case MCSessionStateNotConnected:
            NSLog(@"未连接!");
            break;
        case MCSessionStateConnecting:
            NSLog(@"连接中...");
            break;
        case MCSessionStateConnected:
            NSLog(@"已连接.");
            break;
        default:
            break;
    }
}

// Received data from remote peer.
- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID{
    if (data != nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.imageView.image = [UIImage imageWithData:data];
        });
    }
}

// Received a byte stream from remote peer.
- (void)    session:(MCSession *)session
   didReceiveStream:(NSInputStream *)stream
           withName:(NSString *)streamName
           fromPeer:(MCPeerID *)peerID{
    
}

// Start receiving a resource from remote peer.
- (void)session:(MCSession *)session
didStartReceivingResourceWithName:(NSString *)resourceName
       fromPeer:(MCPeerID *)peerID
   withProgress:(NSProgress *)progress{
    NSLog(@"----progress:%@", progress);
}

// Finished receiving a resource from remote peer and saved the content
// in a temporary location - the app is responsible for moving the file
// to a permanent location within its sandbox.
- (void)                    session:(MCSession *)session
 didFinishReceivingResourceWithName:(NSString *)resourceName
                           fromPeer:(MCPeerID *)peerID
                              atURL:(NSURL *)localURL
                          withError:(nullable NSError *)error{
    
}

#pragma mark - UIImagePickerControllerDelegate
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    self.imageView.image = info[UIImagePickerControllerOriginalImage];
    [picker dismissViewControllerAnimated:YES completion:nil];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
