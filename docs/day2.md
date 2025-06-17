# 客户端caller开发
## 客户端测试用例
- `send_request`发送 RPC 请求的函数，模拟客户端调用远程服务,包含设置 RPC 方法的请求参数，定义 RPC 方法的响应参数，调用远程的 Login 方法
- `KrpcApplication::Init(argc, argv)`初始化 RPC 框架，解析命令行参数并加载配置文件
- 创建日志对象
- `KrpcLogger logger("MyRPC")`启动多线程进行并发测试
- `t.join();`等待所有线程执行完毕

> 可以看到，由`protobuf`生成的供`caller`调用的RPC方法其实里面都调用了`channel_CallMethod()`，继续深入下去发现`channel_`是`RrpcChannel`类，`RpcChannel`类是一个虚函
数，里面有一个虚方法`CallMethod（）`，也就是说，我们用户需要自己实现一个继承于`RpcChannel`的派生类，这个派生类要实现`CallMethod（）`的定义。