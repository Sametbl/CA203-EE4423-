#include "coremark.h"
ee_s32 get_seed_32(int i);

/* iterate() from core_main.c */
static void *iterate(void *pres) {
    ee_u32 i; ee_u16 crc;
    core_results *res = (core_results *)pres;
    ee_u32 iterations = res->iterations;
    res->crc = res->crclist = res->crcmatrix = res->crcstate = 0;
    for (i = 0; i < iterations; i++) {
        crc      = core_bench_list(res,  1);
        res->crc = crcu16(crc, res->crc);
        crc      = core_bench_list(res, -1);
        res->crc = crcu16(crc, res->crc);
        if (i == 0) res->crclist = res->crc;
    }
    return NULL;
}

static ee_u16 matrix_known_crc[] = { 0xbe52, 0x1199, 0x5608, 0x1fd7, 0x0747 };
static ee_s16 pick_known_id(ee_u16 c){
    switch (c){case 0x8a02:return 0;case 0x7b05:return 1;case 0x4eaf:return 2;case 0xe9f5:return 3;case 0x18f2:return 4;default:return -1;}
}

int main(void){
    core_results res; portable_init(&res.port,0,0);

    res.seed1=get_seed_32(1);
    res.seed2=get_seed_32(2);
    res.seed3=get_seed_32(3);
    res.iterations=1;
    res.execs=ID_LIST|ID_MATRIX|ID_STATE;

    ee_u8 stack_memblock[TOTAL_DATA_SIZE];
    res.size = TOTAL_DATA_SIZE/3;
    res.memblock[0]=stack_memblock;
    res.memblock[1]=(void*)(stack_memblock + res.size*0);
    res.memblock[2]=(void*)(stack_memblock + res.size*1);
    res.memblock[3]=(void*)(stack_memblock + res.size*2);

    res.list = core_list_init(res.size, (list_head*)res.memblock[1], res.seed1);
    core_init_matrix(res.size, res.memblock[2],
                     (ee_s32)res.seed1 | ((ee_s32)res.seed2<<16), &res.mat);
    core_init_state(res.size, res.seed1, res.memblock[3]);

    iterate(&res);

    ee_u16 seedcrc=0;
    seedcrc=crc16(res.seed1,seedcrc);
    seedcrc=crc16(res.seed2,seedcrc);
    seedcrc=crc16(res.seed3,seedcrc);
    seedcrc=crc16(res.size, seedcrc);
    ee_s16 id=pick_known_id(seedcrc);

    ee_printf("seedcrc=0x%04x\n", seedcrc);
    if (id>=0){
        ee_printf("MATRIX: got=0x%04x expect=0x%04x  %s\n",
                  res.crcmatrix, matrix_known_crc[id],
                  (res.crcmatrix==matrix_known_crc[id])?"PASS":"FAIL");
    } else {
        ee_printf("MATRIX: got=0x%04x (no golden)\n", res.crcmatrix);
    }
    portable_fini(&res.port);
    return 0;
}
