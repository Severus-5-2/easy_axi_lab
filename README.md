# Easy AXI Lab — 环境说明

实验介绍、获取仓库、提交流程见 [docs/LAB_GUIDE.md](docs/LAB_GUIDE.md)。

安装工具

```bash
sudo apt-get install iverilog gtkwave make git

iverilog -V
```

## 仿真命令

所有命令在 `sim/` 目录下执行：

```bash
cd sim

make test                  # 跑两个 lab，输出通过数
make test-fifo             # 只跑 FIFO
make test-axi              # 只跑 AXI-Lite

make wave LAB=fifo TC=2    # 跑 FIFO case 2 并打开 GTKWave
make wave LAB=axi  TC=3    # 跑 AXI case 3 并打开 GTKWave

make clean                 # 清掉仿真产物
```

单独跑一个 case：

```bash
cd labs/fifo/sim && make test TC=3
cd labs/axi_lite/sim && make test TC=4
```

## 仓库结构

```
easy_axi_lab/
├── labs/
│   ├── fifo/
│   │   ├── rtl/sync_fifo.v  
│   │   ├── tb/  
│   │   └── sim/Makefile
│   └── axi_lite/
│       ├── rtl/axi_lite_slave.v   
│       ├── tb/              
│       └── sim/Makefile
├── sim/Makefile               
├── docs/LAB_GUIDE.md            
└── README.md
```
