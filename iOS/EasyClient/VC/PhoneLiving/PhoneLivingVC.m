#import "PhoneLivingVC.h"
#import "EasyCameraCell.h"
#import "EasyCamera.h"
#import "EasyUrl.h"

@interface PhoneLivingVC ()<NetRequestDelegate>
{
    NetRequestTool *_requestTool;
      NSMutableArray *_dataArr;
    UiotHUD *_HUD;
    NSString *_urlStr;
    EasyUrl *_urlModel;
}
@property(nonatomic,strong) NetRequestTool *requestTool;
@end

@implementation PhoneLivingVC

static NSString *cellIdentifier1 = @"Cell1";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    [self initSomeView];
    _dataArr = [NSMutableArray array];
    self.requestTool = [[NetRequestTool alloc]init];
    self.requestTool.delegate = self;
    _urlStr= @"http://121.40.50.44:10000/api/getdevicelist?AppType=EasyCamera&TerminalType=Android";
}

- (void)initSomeView
{
    self.view.backgroundColor = [UIColor whiteColor];
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc]init];
    //定义每个UICollectionView 横向的间距
    layout.minimumLineSpacing = 2;
    //定义每个UICollectionView 纵向的间距
    layout.minimumInteritemSpacing = 2;
    //定义每个UICollectionView 的边距距
    layout.sectionInset = UIEdgeInsetsMake(0, 2, 5, 2);//上左下右
    self.collectionView = [[UICollectionView alloc]initWithFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight-40-64) collectionViewLayout:layout];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.showsHorizontalScrollIndicator = NO;
    self.collectionView.showsVerticalScrollIndicator = NO;
    self.collectionView.backgroundColor = [UIColor whiteColor];
    
    
    [self.collectionView registerClass:[EasyCameraCell class] forCellWithReuseIdentifier:cellIdentifier1];
    
    [self.view addSubview:self.collectionView];
    
    [self.view addSubview:self.collectionView];
    
    __weak typeof(self) weakSelf = self;
    //1. 添加头部控件的方法
    self.collectionView.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        [_HUD show:YES];
        [weakSelf requestListData];
    }];
    
}

#pragma mark -  receiveData
- (void)receiveData:(NSMutableArray *)sender
{
    _dataArr = sender;
    [self.collectionView.mj_header endRefreshing];
    [_HUD hide:YES afterDelay:0.5];
    [self.collectionView reloadData];
}
// 请求数据
- (void)requestListData
{
    [self.requestTool  requestListData:_urlStr];
}

// 返回Items的个数 （图片的个数）
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _dataArr.count;
}

// item大小
-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake((ScreenWidth-10)/2, (ScreenWidth-10)/2);
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    EasyCameraCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier1 forIndexPath:indexPath];
    
    EasyCamera *model = _dataArr[indexPath.row];
    
    [cell produceCellModel:model];
    
    cell.backgroundColor = [UIColor orangeColor];
    
    return cell;
    
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    EasyCamera *model = _dataArr[indexPath.row];
    
    AFHTTPSessionManager * manager = [AFHTTPSessionManager manager];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"html/text",@"text/plain", nil];
    NSString *urlStr =[NSString stringWithFormat:@"http://121.40.50.44:10000/api/getdevicestream?device=%@&channel=0&protocol=RTSP&reserve=1",model.serial];
    [manager POST:urlStr parameters:nil progress:^(NSProgress * _Nonnull uploadProgress) {
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary *easyDic = [responseObject objectForKey:@"EasyDarwin"];
        NSDictionary *headerDic =  [easyDic objectForKey:@"Header"];
        NSDictionary *bodyDic =  [easyDic objectForKey:@"Body"];
        if ([[headerDic objectForKey:@"ErrorNum"] isEqualToString:@"200"]) {
            _urlModel = [[EasyUrl alloc]init];
            _urlModel.channel = [bodyDic objectForKey:@"Channel"];
            _urlModel.protocol = [bodyDic objectForKey:@"Protocol"];
            _urlModel.reserve = [bodyDic objectForKey:@"Reserve"];
            _urlModel.serial = [bodyDic objectForKey:@"Serial"];
            _urlModel.url = [bodyDic objectForKey:@"URL"];
            PlayViewController *playVC = [[PlayViewController alloc]init];
            playVC.urlModel = _urlModel;
            [self presentViewController:playVC animated:YES completion:nil];
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"error====%@",error);
    }];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end