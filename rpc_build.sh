第一步：进入到krpc文件
cd HRPC

第二步：生成项目可执行程序
mkdir build && cd build && cmake .. && make -j${nproc}

第三步：然后进入到example文件夹下，找到user.proto文件执行以下命令,会生成user.pb.h和user.pb.cc：
cd example
protoc --cpp_out=. user.proto

第四步：进入到src文件下，找到Krpcheader.proto文件同样会生成如上pb.h和pb.cc文件
cd src
protoc --cpp_out=. Krpcheader.proto

