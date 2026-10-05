	.text
	.attribute	4, 16
	.attribute	5, "rv64i2p1_m2p0_a2p1_f2p2_d2p2_c2p0_v1p0_zicsr2p0_zmmul1p0_zfhmin1p0_zve32f1p0_zve32x1p0_zve64d1p0_zve64f1p0_zve64x1p0_zvfh1p0_zvfhmin1p0_zvl128b1p0_zvl256b1p0_zvl32b1p0_zvl64b1p0_xsfvcp1p0"
	.file	"LLVMDialectModule"
	.globl	kernel                          # -- Begin function kernel
	.p2align	1
	.type	kernel,@function
kernel:                                 # @kernel
.Lfunc_begin0:
	.cfi_startproc
# %bb.0:
	addi	sp, sp, -176
	.cfi_def_cfa_offset 176
	sd	ra, 168(sp)                     # 8-byte Folded Spill
	sd	s0, 160(sp)                     # 8-byte Folded Spill
	sd	s1, 152(sp)                     # 8-byte Folded Spill
	sd	s2, 144(sp)                     # 8-byte Folded Spill
	sd	s3, 136(sp)                     # 8-byte Folded Spill
	sd	s4, 128(sp)                     # 8-byte Folded Spill
	sd	s5, 120(sp)                     # 8-byte Folded Spill
	sd	s6, 112(sp)                     # 8-byte Folded Spill
	sd	s7, 104(sp)                     # 8-byte Folded Spill
	sd	s8, 96(sp)                      # 8-byte Folded Spill
	sd	s9, 88(sp)                      # 8-byte Folded Spill
	sd	s10, 80(sp)                     # 8-byte Folded Spill
	sd	s11, 72(sp)                     # 8-byte Folded Spill
	.cfi_offset ra, -8
	.cfi_offset s0, -16
	.cfi_offset s1, -24
	.cfi_offset s2, -32
	.cfi_offset s3, -40
	.cfi_offset s4, -48
	.cfi_offset s5, -56
	.cfi_offset s6, -64
	.cfi_offset s7, -72
	.cfi_offset s8, -80
	.cfi_offset s9, -88
	.cfi_offset s10, -96
	.cfi_offset s11, -104
	mv	t4, a6
	mv	s5, a1
	li	a0, 0
	ld	a1, 200(sp)
	sd	a1, 16(sp)                      # 8-byte Folded Spill
	lui	a1, 3
	addiw	a1, a1, -1281
	sd	a1, 32(sp)                      # 8-byte Folded Spill
.Lpcrel_hi0:
	auipc	a1, %got_pcrel_hi(Y_spad)
	ld	a1, %pcrel_lo(.Lpcrel_hi0)(a1)
	sd	a1, 64(sp)                      # 8-byte Folded Spill
	vsetivli	zero, 8, e32, m1, ta, ma
	vmv.v.i	v8, 0
	lui	a1, 1
	addiw	a1, a1, -1
	sd	a1, 56(sp)                      # 8-byte Folded Spill
.Lpcrel_hi1:
	auipc	a1, %got_pcrel_hi(W_spad)
	ld	s4, %pcrel_lo(.Lpcrel_hi1)(a1)
.Lpcrel_hi2:
	auipc	a1, %got_pcrel_hi(X_spad)
	ld	s8, %pcrel_lo(.Lpcrel_hi2)(a1)
	lui	a1, 262147
	slli	a1, a1, 2
	addi	a4, a1, 4
	lui	a1, 131074
	addiw	a1, a1, 1
	slli	a1, a1, 19
	addi	s2, a1, 128
	li	a1, 1
	slli	a2, a1, 44
	addi	t3, a2, 1
	slli	a1, a1, 32
	addi	a5, a1, 8
	lui	a3, 8192
	addiw	a3, a3, 513
	slli	a3, a3, 23
	addi	s0, a3, 128
	li	a3, 43
	slli	a3, a3, 40
	addi	s1, a3, 1
	addi	a3, a1, 128
	lui	s3, 1376
	lui	a1, 262171
	slli	a1, a1, 2
	addi	a1, a1, 4
	sd	a1, 8(sp)                       # 8-byte Folded Spill
	mv	a6, a0
	j	.LBB0_2
.LBB0_1:                                #   in Loop: Header=BB0_2 Depth=1
	addi	a6, a6, 8
.LBB0_2:                                # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_5 Depth 2
                                        #       Child Loop BB0_8 Depth 3
                                        #         Child Loop BB0_11 Depth 4
                                        #           Child Loop BB0_14 Depth 5
                                        #             Child Loop BB0_16 Depth 6
	li	a1, 7
	blt	a1, a6, .LBB0_17
# %bb.3:                                #   in Loop: Header=BB0_2 Depth=1
	li	a2, 0
	li	a7, 0
	slli	s9, a6, 12
	sd	a6, 24(sp)                      # 8-byte Folded Spill
	j	.LBB0_5
.LBB0_4:                                #   in Loop: Header=BB0_5 Depth=2
	lui	a1, 3
	addiw	a1, a1, -1280
	ld	a6, 24(sp)                      # 8-byte Folded Reload
	mul	a1, a6, a1
	ld	a7, 40(sp)                      # 8-byte Folded Reload
	add	a1, a1, a7
	slli	a1, a1, 2
	ld	a2, 16(sp)                      # 8-byte Folded Reload
	add	a1, a1, a2
	ld	a2, 8(sp)                       # 8-byte Folded Reload
	#APP
	.insn r 43, 3, 0, zero, s2, a2
	#NO_APP
	#APP
	.insn r 43, 3, 4, zero, a0, s1
	#NO_APP
	#APP
	.insn r 43, 3, 5, zero, a0, a5
	#NO_APP
	ld	a2, 64(sp)                      # 8-byte Folded Reload
	#APP
	.insn r 43, 3, 3, zero, a1, a2
	#NO_APP
	addi	a7, a7, 128
	ld	a2, 48(sp)                      # 8-byte Folded Reload
	addi	a2, a2, 512
.LBB0_5:                                #   Parent Loop BB0_2 Depth=1
                                        # =>  This Loop Header: Depth=2
                                        #       Child Loop BB0_8 Depth 3
                                        #         Child Loop BB0_11 Depth 4
                                        #           Child Loop BB0_14 Depth 5
                                        #             Child Loop BB0_16 Depth 6
	ld	a1, 32(sp)                      # 8-byte Folded Reload
	blt	a1, a7, .LBB0_1
# %bb.6:                                #   in Loop: Header=BB0_5 Depth=2
	sd	a7, 40(sp)                      # 8-byte Folded Spill
	li	s10, 0
	vsetivli	zero, 8, e32, m1, ta, ma
	ld	a1, 64(sp)                      # 8-byte Folded Reload
	vse32.v	v8, (a1)
	sd	a2, 48(sp)                      # 8-byte Folded Spill
	j	.LBB0_8
.LBB0_7:                                #   in Loop: Header=BB0_8 Depth=3
	vsetivli	zero, 8, e32, m1, ta, ma
	vle32.v	v9, (s4)
	sf.vc.iv	1, 0, v9, 0
	addi	a1, s4, 32
	vle32.v	v9, (a1)
	addi	a1, s4, 64
	vle32.v	v10, (a1)
	addi	a1, s4, 96
	vle32.v	v11, (a1)
	addi	a1, s4, 128
	vle32.v	v12, (a1)
	sf.vc.iv	1, 0, v9, 0
	sf.vc.iv	1, 0, v10, 0
	sf.vc.iv	1, 0, v11, 0
	sf.vc.iv	1, 0, v12, 0
	addi	a1, s4, 160
	vle32.v	v9, (a1)
	addi	a1, s4, 192
	vle32.v	v10, (a1)
	addi	a1, s4, 224
	vle32.v	v11, (a1)
	addi	a1, s4, 256
	vle32.v	v12, (a1)
	sf.vc.iv	1, 0, v9, 0
	sf.vc.iv	1, 0, v10, 0
	sf.vc.iv	1, 0, v11, 0
	sf.vc.iv	1, 0, v12, 0
	addi	a1, s4, 288
	vle32.v	v9, (a1)
	addi	a1, s4, 320
	vle32.v	v10, (a1)
	addi	a1, s4, 352
	vle32.v	v11, (a1)
	addi	a1, s4, 384
	vle32.v	v12, (a1)
	sf.vc.iv	1, 0, v9, 0
	sf.vc.iv	1, 0, v10, 0
	sf.vc.iv	1, 0, v11, 0
	sf.vc.iv	1, 0, v12, 0
	addi	a1, s4, 416
	vle32.v	v9, (a1)
	addi	a1, s4, 448
	vle32.v	v10, (a1)
	addi	a1, s4, 480
	vle32.v	v11, (a1)
	sf.vc.iv	1, 0, v9, 0
	vle32.v	v9, (s8)
	sf.vc.iv	1, 0, v10, 0
	sf.vc.iv	1, 0, v11, 0
	ld	a6, 64(sp)                      # 8-byte Folded Reload
	vle32.v	v10, (a6)
	sf.vc.iv	0, 0, v9, 0
	li	a1, 8
	vsetvli	zero, a1, e32, m1, ta, ma
	sf.vc.i	1, 0, 0, 4
	vsetivli	zero, 8, e32, m1, ta, ma
	sf.vc.v.i	2, 0, v9, 0
	vfadd.vv	v9, v10, v9
	vse32.v	v9, (a6)
	addi	s10, s10, 128
	add	a2, a2, s3
.LBB0_8:                                #   Parent Loop BB0_2 Depth=1
                                        #     Parent Loop BB0_5 Depth=2
                                        # =>    This Loop Header: Depth=3
                                        #         Child Loop BB0_11 Depth 4
                                        #           Child Loop BB0_14 Depth 5
                                        #             Child Loop BB0_16 Depth 6
	ld	a1, 56(sp)                      # 8-byte Folded Reload
	blt	a1, s10, .LBB0_4
# %bb.9:                                #   in Loop: Header=BB0_8 Depth=3
	li	t1, 0
	j	.LBB0_11
.LBB0_10:                               #   in Loop: Header=BB0_11 Depth=4
	addi	t1, t1, 1
.LBB0_11:                               #   Parent Loop BB0_2 Depth=1
                                        #     Parent Loop BB0_5 Depth=2
                                        #       Parent Loop BB0_8 Depth=3
                                        # =>      This Loop Header: Depth=4
                                        #           Child Loop BB0_14 Depth 5
                                        #             Child Loop BB0_16 Depth 6
	blt	a0, t1, .LBB0_7
# %bb.12:                               #   in Loop: Header=BB0_11 Depth=4
	li	a7, 0
	slli	ra, t1, 3
	slli	t0, t1, 15
	mv	t2, s4
	mv	s7, a2
	j	.LBB0_14
.LBB0_13:                               #   in Loop: Header=BB0_14 Depth=5
	addi	a7, a7, 1
	add	s7, s7, s3
	addi	t2, t2, 512
.LBB0_14:                               #   Parent Loop BB0_2 Depth=1
                                        #     Parent Loop BB0_5 Depth=2
                                        #       Parent Loop BB0_8 Depth=3
                                        #         Parent Loop BB0_11 Depth=4
                                        # =>        This Loop Header: Depth=5
                                        #             Child Loop BB0_16 Depth 6
	blt	a0, a7, .LBB0_10
# %bb.15:                               #   in Loop: Header=BB0_14 Depth=5
	li	s6, 0
	slli	a1, a7, 3
	add	t5, ra, a1
	slli	a1, a7, 7
	add	t6, t0, a1
	add	a1, s9, s10
	add	a1, a1, t6
	slli	a1, a1, 2
	add	a1, a1, s5
	slli	t5, t5, 2
	add	t6, s8, t5
	mv	t5, t2
	mv	s11, s7
	bltz	a0, .LBB0_13
.LBB0_16:                               #   Parent Loop BB0_2 Depth=1
                                        #     Parent Loop BB0_5 Depth=2
                                        #       Parent Loop BB0_8 Depth=3
                                        #         Parent Loop BB0_11 Depth=4
                                        #           Parent Loop BB0_14 Depth=5
                                        # =>          This Inner Loop Header: Depth=6
	#APP
	.insn r 43, 3, 0, zero, s2, a4
	#NO_APP
	#APP
	.insn r 43, 3, 4, zero, a0, t3
	#NO_APP
	#APP
	.insn r 43, 3, 5, zero, a0, a5
	#NO_APP
	#APP
	.insn r 43, 3, 2, zero, a1, t6
	#NO_APP
	add	a6, s11, t4
	#APP
	.insn r 43, 3, 0, zero, s0, a4
	#NO_APP
	#APP
	.insn r 43, 3, 4, zero, a0, s1
	#NO_APP
	#APP
	.insn r 43, 3, 5, zero, a0, a3
	#NO_APP
	#APP
	.insn r 43, 3, 2, zero, a6, t5
	#NO_APP
	addi	s6, s6, 1
	addi	s11, s11, 512
	addi	t5, t5, 512
	bge	a0, s6, .LBB0_16
	j	.LBB0_13
.LBB0_17:
	ld	ra, 168(sp)                     # 8-byte Folded Reload
	ld	s0, 160(sp)                     # 8-byte Folded Reload
	ld	s1, 152(sp)                     # 8-byte Folded Reload
	ld	s2, 144(sp)                     # 8-byte Folded Reload
	ld	s3, 136(sp)                     # 8-byte Folded Reload
	ld	s4, 128(sp)                     # 8-byte Folded Reload
	ld	s5, 120(sp)                     # 8-byte Folded Reload
	ld	s6, 112(sp)                     # 8-byte Folded Reload
	ld	s7, 104(sp)                     # 8-byte Folded Reload
	ld	s8, 96(sp)                      # 8-byte Folded Reload
	ld	s9, 88(sp)                      # 8-byte Folded Reload
	ld	s10, 80(sp)                     # 8-byte Folded Reload
	ld	s11, 72(sp)                     # 8-byte Folded Reload
	addi	sp, sp, 176
	ret
.Lfunc_end0:
	.size	kernel, .Lfunc_end0-kernel
	.cfi_endproc
	.section	.stack_sizes,"o",@progbits,.text
	.quad	.Lfunc_begin0
	.ascii	"\260\001"
	.text
                                        # -- End function
	.globl	wrapper_kernel                  # -- Begin function wrapper_kernel
	.p2align	1
	.type	wrapper_kernel,@function
wrapper_kernel:                         # @wrapper_kernel
.Lfunc_begin1:
	.cfi_startproc
# %bb.0:
	addi	sp, sp, -160
	.cfi_def_cfa_offset 160
	sd	ra, 152(sp)                     # 8-byte Folded Spill
	sd	s0, 144(sp)                     # 8-byte Folded Spill
	sd	s1, 136(sp)                     # 8-byte Folded Spill
	sd	s2, 128(sp)                     # 8-byte Folded Spill
	sd	s3, 120(sp)                     # 8-byte Folded Spill
	sd	s4, 112(sp)                     # 8-byte Folded Spill
	sd	s5, 104(sp)                     # 8-byte Folded Spill
	sd	s6, 96(sp)                      # 8-byte Folded Spill
	sd	s7, 88(sp)                      # 8-byte Folded Spill
	sd	s8, 80(sp)                      # 8-byte Folded Spill
	sd	s9, 72(sp)                      # 8-byte Folded Spill
	sd	s10, 64(sp)                     # 8-byte Folded Spill
	sd	s11, 56(sp)                     # 8-byte Folded Spill
	.cfi_offset ra, -8
	.cfi_offset s0, -16
	.cfi_offset s1, -24
	.cfi_offset s2, -32
	.cfi_offset s3, -40
	.cfi_offset s4, -48
	.cfi_offset s5, -56
	.cfi_offset s6, -64
	.cfi_offset s7, -72
	.cfi_offset s8, -80
	.cfi_offset s9, -88
	.cfi_offset s10, -96
	.cfi_offset s11, -104
	ld	s6, 184(sp)
	ld	s9, 168(sp)
	ld	s10, 160(sp)
	mv	s3, a7
	mv	s4, a6
	mv	s5, a5
	mv	s1, a1
	lui	a0, 86
	call	malloc
	mv	s2, a0
	lui	a0, 22
	addiw	s11, a0, -2048
	lui	a0, 32
	call	malloc
	mv	s0, a0
	li	a2, 0
	li	t0, 0
	li	t1, 0
	lui	a5, 8
	lui	a6, 1
	addiw	a4, a6, -1
	addiw	a5, a5, -1
	lui	a7, 4
	j	.LBB1_2
.LBB1_1:                                #   in Loop: Header=BB1_2 Depth=1
	addi	t1, t1, 1
	add	t0, t0, a7
	add	a2, a2, a6
.LBB1_2:                                # =>This Loop Header: Depth=1
                                        #     Child Loop BB1_5 Depth 2
	bgtz	t1, .LBB1_8
# %bb.3:                                #   in Loop: Header=BB1_2 Depth=1
	li	a3, 0
	mv	a1, t0
	j	.LBB1_5
.LBB1_4:                                #   in Loop: Header=BB1_5 Depth=2
	addi	a3, a3, 1
	addi	a1, a1, 4
.LBB1_5:                                #   Parent Loop BB1_2 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	blt	a4, a3, .LBB1_1
# %bb.6:                                #   in Loop: Header=BB1_5 Depth=2
	add	a0, a2, a3
	blt	a5, a0, .LBB1_4
# %bb.7:                                #   in Loop: Header=BB1_5 Depth=2
	add	a0, s1, a1
	flw	fa5, 0(a0)
	add	a0, s0, a1
	fsw	fa5, 0(a0)
	j	.LBB1_4
.LBB1_8:
	li	a2, 0
	li	a6, 0
	li	a7, 0
	lui	a1, 11
	addiw	s7, a1, -1024
	lui	a1, 3
	addiw	s8, a1, -1280
	addiw	a3, a1, -1281
	lui	a1, 21
	addiw	a4, a1, 2047
	j	.LBB1_10
.LBB1_9:                                #   in Loop: Header=BB1_10 Depth=1
	addi	a7, a7, 1
	add	a6, a6, s7
	add	a2, a2, s8
.LBB1_10:                               # =>This Loop Header: Depth=1
                                        #     Child Loop BB1_13 Depth 2
	bgtz	a7, .LBB1_16
# %bb.11:                               #   in Loop: Header=BB1_10 Depth=1
	li	a5, 0
	mv	a1, a6
	j	.LBB1_13
.LBB1_12:                               #   in Loop: Header=BB1_13 Depth=2
	addi	a5, a5, 1
	addi	a1, a1, 4
.LBB1_13:                               #   Parent Loop BB1_10 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	blt	a3, a5, .LBB1_9
# %bb.14:                               #   in Loop: Header=BB1_13 Depth=2
	add	a0, a2, a5
	blt	a4, a0, .LBB1_12
# %bb.15:                               #   in Loop: Header=BB1_13 Depth=2
	add	a0, s6, a1
	flw	fa5, 0(a0)
	add	a0, s2, a1
	fsw	fa5, 0(a0)
	j	.LBB1_12
.LBB1_16:
	sd	zero, 32(sp)
	sd	s2, 24(sp)
	sd	s2, 16(sp)
	sd	s11, 40(sp)
	sd	s10, 0(sp)
	li	a0, 1
	sd	a0, 48(sp)
	lui	a3, 8
	li	a4, 1
	sd	s9, 8(sp)
	mv	a0, s0
	mv	a1, s0
	li	a2, 0
	mv	a5, s5
	mv	a6, s4
	mv	a7, s3
	call	kernel
	li	a2, 0
	li	t0, 0
	li	t1, 0
	lui	a6, 1
	addiw	a4, a6, -1
	lui	a5, 8
	addiw	a5, a5, -1
	lui	a7, 4
	j	.LBB1_18
.LBB1_17:                               #   in Loop: Header=BB1_18 Depth=1
	addi	t1, t1, 1
	add	t0, t0, a7
	add	a2, a2, a6
.LBB1_18:                               # =>This Loop Header: Depth=1
                                        #     Child Loop BB1_21 Depth 2
	bgtz	t1, .LBB1_24
# %bb.19:                               #   in Loop: Header=BB1_18 Depth=1
	li	a3, 0
	mv	a1, t0
	j	.LBB1_21
.LBB1_20:                               #   in Loop: Header=BB1_21 Depth=2
	addi	a3, a3, 1
	addi	a1, a1, 4
.LBB1_21:                               #   Parent Loop BB1_18 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	blt	a4, a3, .LBB1_17
# %bb.22:                               #   in Loop: Header=BB1_21 Depth=2
	add	a0, a2, a3
	blt	a5, a0, .LBB1_20
# %bb.23:                               #   in Loop: Header=BB1_21 Depth=2
	add	a0, s0, a1
	flw	fa5, 0(a0)
	add	a0, s1, a1
	fsw	fa5, 0(a0)
	j	.LBB1_20
.LBB1_24:
	li	s0, 0
	li	s1, 0
	li	a2, 0
	lui	a1, 3
	addiw	a3, a1, -1281
	lui	a1, 21
	addiw	a4, a1, 2047
	j	.LBB1_26
.LBB1_25:                               #   in Loop: Header=BB1_26 Depth=1
	addi	a2, a2, 1
	add	s1, s1, s7
	add	s0, s0, s8
.LBB1_26:                               # =>This Loop Header: Depth=1
                                        #     Child Loop BB1_29 Depth 2
	bgtz	a2, .LBB1_32
# %bb.27:                               #   in Loop: Header=BB1_26 Depth=1
	li	a5, 0
	mv	a1, s1
	j	.LBB1_29
.LBB1_28:                               #   in Loop: Header=BB1_29 Depth=2
	addi	a5, a5, 1
	addi	a1, a1, 4
.LBB1_29:                               #   Parent Loop BB1_26 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	blt	a3, a5, .LBB1_25
# %bb.30:                               #   in Loop: Header=BB1_29 Depth=2
	add	a0, s0, a5
	blt	a4, a0, .LBB1_28
# %bb.31:                               #   in Loop: Header=BB1_29 Depth=2
	add	a0, s2, a1
	flw	fa5, 0(a0)
	add	a0, s6, a1
	fsw	fa5, 0(a0)
	j	.LBB1_28
.LBB1_32:
	ld	ra, 152(sp)                     # 8-byte Folded Reload
	ld	s0, 144(sp)                     # 8-byte Folded Reload
	ld	s1, 136(sp)                     # 8-byte Folded Reload
	ld	s2, 128(sp)                     # 8-byte Folded Reload
	ld	s3, 120(sp)                     # 8-byte Folded Reload
	ld	s4, 112(sp)                     # 8-byte Folded Reload
	ld	s5, 104(sp)                     # 8-byte Folded Reload
	ld	s6, 96(sp)                      # 8-byte Folded Reload
	ld	s7, 88(sp)                      # 8-byte Folded Reload
	ld	s8, 80(sp)                      # 8-byte Folded Reload
	ld	s9, 72(sp)                      # 8-byte Folded Reload
	ld	s10, 64(sp)                     # 8-byte Folded Reload
	ld	s11, 56(sp)                     # 8-byte Folded Reload
	addi	sp, sp, 160
	ret
.Lfunc_end1:
	.size	wrapper_kernel, .Lfunc_end1-wrapper_kernel
	.cfi_endproc
	.section	.stack_sizes,"o",@progbits,.text
	.quad	.Lfunc_begin1
	.ascii	"\240\001"
	.text
                                        # -- End function
	.section	".note.GNU-stack","",@progbits
