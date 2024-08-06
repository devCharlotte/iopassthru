# 변수 정의 
# $1, $2 스크립트 실행하면 인자로 전달되는 char dev, block dev 의 경로
dev_char_str=$1;  
dev_blk_str=$2;

# 함수 정의 
run()
{
  # 받는 인자 2개
	local pt=$1; # 테스트 유형 char 1 / block 0
	local od=$2; # output 디렉토리 path

  # 테스트 유형에 따라 달라지는 종속 변인
	local dev_str; 
	local cs;

  # 테스트 실행할 코어 지정 
	core_str='0';

  
	if [ $pt -eq 1 ]
	then
		cs=' -O0 -u1';
		of='pt';
		dev_str=$dev_char_str;
	else
		cs=' -O1';
		of='blk';
		dev_str=$dev_blk_str;
	fi

	printf "Test: ${dev_str} on cpu ${core_str}\n"

	kstr="taskset -c $core_str t/io_uring -r4 -b512 -d128 -c32 -s32 -p0 -F1 -B0 -P0 $cs -n1 $dev_str"
	echo $kstr
	if [ $pt -eq 1 ]
	then
		printf "For ${dev_str} char device\n" > ${od}/$of
	else
		printf "For ${dev_str} block device \n" > ${od}/$of
	fi

	printf "\nconfig = plain\n" >> ${od}/$of

	taskset -c $core_str t/io_uring -r4 -b512 -d128 -c32 -s32 -p0 -F1 -B0 -P0 $cs -n1 $dev_str >> ${od}/$of

	printf "\nconfig = plain + fb\n" >>  ${od}/$of

	taskset -c $core_str t/io_uring -r4 -b512 -d128 -c32 -s32 -p0 -F1 -B1 -P0 $cs -n1 $dev_str >> ${od}/$of

	printf "\nconfig = plain + iopoll\n" >> ${od}/$of

	taskset -c $core_str t/io_uring -r4 -b512 -d128 -c32 -s32 -p1 -F1 -B0 -P0 $cs -n1 $dev_str >> ${od}/$of

	printf "\nconfig = plain + iopoll + fb\n" >> ${od}/$of

	taskset -c $core_str t/io_uring -r4 -b512 -d128 -c32 -s32 -p1 -F1 -B1 -P0 $cs -n1 $dev_str >> ${od}/$of
}


# outdir 변수를 현재 날짜와 시간으로 설정하고 디렉토리 생성
outdir=out-$(date +"%d-%m-%Y-%H-%M-%S")
mkdir $outdir
echo "output will be inside the dir $outdir"

# char block 디바이스에 대한 run 함수 호출하고 테스트 수행

#passthru test
echo "running passthru test on 1 device(s)"
run 1 $outdir

#block test
echo "running block test on 1 device(s)"
run 0 $outdir
