view wave
delete wave *
restart -f
add wave DEBUG_PROC/*
add wave DEBUG_PROC/TRACER/*
#add wave DEBUG_PROC/PROC/CORE/*
#add wave DEBUG_PROC/PROC/TRANSLATOR/*
#add wave DEBUG_PROC/PROC/TRANSLATOR/UOP_Q/*
#add wave DEBUG_PROC/PROC/TRANSLATOR/FETCHER/*
#add wave DEBUG_PROC/PROC/TRANSLATOR/DECODER/*
#add wave DEBUG_PROC/PROC/TRANSLATOR/XLATOR/*
add wave DEBUG_PROC/MPU_main/*
add wave DEBUG_PROC/MPU_main/schedule/*
add wave DEBUG_PROC/MPU_main/page/*

#add wave DEBUG_PROC/JPC_main/*
#add wave DEBUG_PROC/VDP_top_inst/*
radix -hexadecimal

force NMI_ 1 	0
#force INT_b 1	0

run 350000
#run  35000000
#run 50000000

