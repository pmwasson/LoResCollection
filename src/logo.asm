; --------------------------------------------------------------------
; ..\images\logo.png PNG (40, 48) RGBA
; logo.png None (40, 48) P
; assume background =  7
logo_0x400:
  ; full bytes
  lda #$dd
  sta $58d
  sta $58e
  sta $58f
  sta $590
  sta $591
  sta $592
  sta $596
  sta $597
  sta $598
  sta $599
  sta $59a
  sta $59b
  sta $59e
  sta $59f
  sta $5a0
  sta $5a1
  sta $5a2
  sta $5a3
  sta $5a4
  sta $5a5
  sta $60d
  sta $60e
  sta $613
  sta $616
  sta $617
  sta $624
  sta $68d
  sta $68e
  sta $692
  sta $693
  sta $696
  sta $697
  sta $698
  sta $699
  sta $69a
  sta $6a2
  sta $70d
  sta $70e
  sta $712
  sta $716
  sta $717
  sta $720
  sta $78d
  sta $78e
  sta $792
  sta $793
  sta $796
  sta $797
  sta $79e
  sta $79f
  lda #$0
  sta $60f
  sta $614
  sta $618
  sta $694
  sta $718
  sta $78f
  sta $794
  sta $42b
  sta $437
  sta $43c
  sta $444
  sta $44e
  sta $4ab
  sta $52b
  sta $5b5
  sta $5ba
  sta $6cd
  sta $4f5
  sta $575
  sta $5f4
  lda #$d0
  sta $623
  sta $68f
  sta $713
  sta $798
  sta $7a0
  lda #$d
  sta $625
  sta $6a3
  sta $70f
  sta $721
  sta $436
  sta $43b
  sta $43f
  sta $440
  sta $441
  sta $442
  sta $443
  sta $447
  sta $448
  sta $449
  sta $44a
  sta $44b
  sta $44c
  sta $44d
  lda #$bb
  sta $429
  sta $42a
  sta $4a9
  sta $4aa
  sta $529
  sta $52a
  sta $534
  sta $538
  sta $5a9
  sta $5aa
  sta $5ab
  sta $5ac
  sta $5ad
  sta $5ae
  sta $5af
  sta $5b0
  sta $5b3
  sta $5b4
  sta $5b8
  sta $5b9
  sta $634
  sta $638
  lda #$b
  sta $535
  sta $536
  sta $537
  sta $639
  sta $6b6
  sta $6b7
  lda #$b0
  sta $635
  lda #$cc
  sta $640
  sta $641
  sta $642
  sta $643
  sta $644
  sta $645
  sta $646
  sta $647
  sta $648
  sta $649
  sta $64a
  sta $64b
  sta $64c
  sta $6c0
  sta $6c1
  sta $6c2
  sta $740
  sta $741
  sta $742
  sta $7c0
  sta $7c1
  sta $7c2
  sta $7c3
  sta $7c4
  sta $7c5
  sta $7c6
  sta $7c7
  sta $7c8
  sta $7c9
  sta $7ca
  sta $471
  sta $472
  sta $473
  sta $4f2
  sta $4f3
  sta $4f4
  sta $568
  sta $569
  sta $56a
  sta $572
  sta $573
  sta $574
  sta $5e9
  sta $5ea
  sta $5eb
  sta $5ec
  sta $5ed
  sta $5ee
  sta $5ef
  sta $5f0
  sta $5f1
  sta $5f2
  sta $5f3
  lda #$c
  sta $6c3
  sta $6c4
  sta $6c5
  sta $6c6
  sta $6c7
  sta $6c8
  sta $6c9
  sta $6ca
  sta $6cb
  sta $6cc
  sta $46a
  sta $46b
  sta $46c
  sta $46d
  sta $46e
  sta $46f
  sta $470
  sta $66b
  sta $66c
  sta $66d
  sta $66e
  sta $66f
  sta $670
  sta $671
  sta $672
  lda #$c0
  sta $474
  ; even bytes
  lda $610
  and #$f0
  sta $610
  lda $611
  and #$f0
  sta $611
  lda $612
  and #$f0
  ora #$d
  sta $612
  lda $619
  and #$f0
  sta $619
  lda $61a
  and #$f0
  sta $61a
  lda $61b
  and #$f0
  sta $61b
  lda $61c
  and #$f0
  sta $61c
  lda $61f
  and #$f0
  sta $61f
  lda $620
  and #$f0
  sta $620
  lda $621
  and #$f0
  sta $621
  lda $622
  and #$f0
  sta $622
  lda $626
  and #$f0
  sta $626
  lda $6a4
  and #$f0
  sta $6a4
  lda $710
  and #$f0
  ora #$d
  sta $710
  lda $711
  and #$f0
  ora #$d
  sta $711
  lda $719
  and #$f0
  sta $719
  lda $71a
  and #$f0
  sta $71a
  lda $71b
  and #$f0
  sta $71b
  lda $722
  and #$f0
  sta $722
  lda $435
  and #$f0
  ora #$d
  sta $435
  lda $43a
  and #$f0
  ora #$d
  sta $43a
  lda $43e
  and #$f0
  ora #$d
  sta $43e
  lda $446
  and #$f0
  ora #$d
  sta $446
  lda $62a
  and #$f0
  sta $62a
  lda $62b
  and #$f0
  sta $62b
  lda $62c
  and #$f0
  sta $62c
  lda $62d
  and #$f0
  sta $62d
  lda $62e
  and #$f0
  sta $62e
  lda $62f
  and #$f0
  sta $62f
  lda $630
  and #$f0
  sta $630
  lda $631
  and #$f0
  sta $631
  lda $633
  and #$f0
  ora #$b
  sta $633
  lda $63a
  and #$f0
  sta $63a
  lda $6b5
  and #$f0
  ora #$b
  sta $6b5
  lda $6b8
  and #$f0
  sta $6b8
  lda $469
  and #$f0
  ora #$c
  sta $469
  lda $5e8
  and #$f0
  ora #$c
  sta $5e8
  lda $66a
  and #$f0
  ora #$c
  sta $66a
  lda $673
  and #$f0
  sta $673
  ; odd bytes
  lda $593
  and #$0f
  ora #$d0
  sta $593
  lda $59c
  and #$0f
  sta $59c
  lda $5a6
  and #$0f
  sta $5a6
  lda $690
  and #$0f
  ora #$d0
  sta $690
  lda $691
  and #$0f
  ora #$d0
  sta $691
  lda $69b
  and #$0f
  sta $69b
  lda $6a1
  and #$0f
  ora #$d0
  sta $6a1
  lda $714
  and #$0f
  sta $714
  lda $71f
  and #$0f
  ora #$d0
  sta $71f
  lda $781
  and #$0f
  ora #$b0
  sta $781
  lda $782
  and #$0f
  ora #$b0
  sta $782
  lda $799
  and #$0f
  ora #$d0
  sta $799
  lda $79a
  and #$0f
  ora #$d0
  sta $79a
  lda $79b
  and #$0f
  ora #$d0
  sta $79b
  lda $7a1
  and #$0f
  ora #$d0
  sta $7a1
  lda $7a2
  and #$0f
  ora #$d0
  sta $7a2
  lda $7a3
  and #$0f
  ora #$d0
  sta $7a3
  lda $7a4
  and #$0f
  ora #$d0
  sta $7a4
  lda $7a5
  and #$0f
  ora #$d0
  sta $7a5
  lda $4b5
  and #$0f
  ora #$b0
  sta $4b5
  lda $4b6
  and #$0f
  ora #$b0
  sta $4b6
  lda $4b7
  and #$0f
  ora #$b0
  sta $4b7
  lda $533
  and #$0f
  ora #$b0
  sta $533
  lda $539
  and #$0f
  ora #$b0
  sta $539
  lda $5b1
  and #$0f
  sta $5b1
  lda $636
  and #$0f
  ora #$b0
  sta $636
  lda $637
  and #$0f
  ora #$b0
  sta $637
  lda $64d
  and #$0f
  sta $64d
  lda $7cb
  and #$0f
  ora #$c0
  sta $7cb
  lda $56b
  and #$0f
  ora #$c0
  sta $56b
  lda $571
  and #$0f
  ora #$c0
  sta $571
  rts
logo_0x800:
  ; full bytes
  lda #$dd
  sta $98d
  sta $98e
  sta $98f
  sta $990
  sta $991
  sta $992
  sta $996
  sta $997
  sta $998
  sta $999
  sta $99a
  sta $99b
  sta $99e
  sta $99f
  sta $9a0
  sta $9a1
  sta $9a2
  sta $9a3
  sta $9a4
  sta $9a5
  sta $a0d
  sta $a0e
  sta $a13
  sta $a16
  sta $a17
  sta $a24
  sta $a8d
  sta $a8e
  sta $a92
  sta $a93
  sta $a96
  sta $a97
  sta $a98
  sta $a99
  sta $a9a
  sta $aa2
  sta $b0d
  sta $b0e
  sta $b12
  sta $b16
  sta $b17
  sta $b20
  sta $b8d
  sta $b8e
  sta $b92
  sta $b93
  sta $b96
  sta $b97
  sta $b9e
  sta $b9f
  lda #$0
  sta $a0f
  sta $a14
  sta $a18
  sta $a94
  sta $b18
  sta $b8f
  sta $b94
  sta $82b
  sta $837
  sta $83c
  sta $844
  sta $84e
  sta $8ab
  sta $92b
  sta $9b5
  sta $9ba
  sta $acd
  sta $8f5
  sta $975
  sta $9f4
  lda #$d0
  sta $a23
  sta $a8f
  sta $b13
  sta $b98
  sta $ba0
  lda #$d
  sta $a25
  sta $aa3
  sta $b0f
  sta $b21
  sta $836
  sta $83b
  sta $83f
  sta $840
  sta $841
  sta $842
  sta $843
  sta $847
  sta $848
  sta $849
  sta $84a
  sta $84b
  sta $84c
  sta $84d
  lda #$bb
  sta $829
  sta $82a
  sta $8a9
  sta $8aa
  sta $929
  sta $92a
  sta $934
  sta $938
  sta $9a9
  sta $9aa
  sta $9ab
  sta $9ac
  sta $9ad
  sta $9ae
  sta $9af
  sta $9b0
  sta $9b3
  sta $9b4
  sta $9b8
  sta $9b9
  sta $a34
  sta $a38
  lda #$b
  sta $935
  sta $936
  sta $937
  sta $a39
  sta $ab6
  sta $ab7
  lda #$b0
  sta $a35
  lda #$cc
  sta $a40
  sta $a41
  sta $a42
  sta $a43
  sta $a44
  sta $a45
  sta $a46
  sta $a47
  sta $a48
  sta $a49
  sta $a4a
  sta $a4b
  sta $a4c
  sta $ac0
  sta $ac1
  sta $ac2
  sta $b40
  sta $b41
  sta $b42
  sta $bc0
  sta $bc1
  sta $bc2
  sta $bc3
  sta $bc4
  sta $bc5
  sta $bc6
  sta $bc7
  sta $bc8
  sta $bc9
  sta $bca
  sta $871
  sta $872
  sta $873
  sta $8f2
  sta $8f3
  sta $8f4
  sta $968
  sta $969
  sta $96a
  sta $972
  sta $973
  sta $974
  sta $9e9
  sta $9ea
  sta $9eb
  sta $9ec
  sta $9ed
  sta $9ee
  sta $9ef
  sta $9f0
  sta $9f1
  sta $9f2
  sta $9f3
  lda #$c
  sta $ac3
  sta $ac4
  sta $ac5
  sta $ac6
  sta $ac7
  sta $ac8
  sta $ac9
  sta $aca
  sta $acb
  sta $acc
  sta $86a
  sta $86b
  sta $86c
  sta $86d
  sta $86e
  sta $86f
  sta $870
  sta $a6b
  sta $a6c
  sta $a6d
  sta $a6e
  sta $a6f
  sta $a70
  sta $a71
  sta $a72
  lda #$c0
  sta $874
  ; even bytes
  lda $a10
  and #$f0
  sta $a10
  lda $a11
  and #$f0
  sta $a11
  lda $a12
  and #$f0
  ora #$d
  sta $a12
  lda $a19
  and #$f0
  sta $a19
  lda $a1a
  and #$f0
  sta $a1a
  lda $a1b
  and #$f0
  sta $a1b
  lda $a1c
  and #$f0
  sta $a1c
  lda $a1f
  and #$f0
  sta $a1f
  lda $a20
  and #$f0
  sta $a20
  lda $a21
  and #$f0
  sta $a21
  lda $a22
  and #$f0
  sta $a22
  lda $a26
  and #$f0
  sta $a26
  lda $aa4
  and #$f0
  sta $aa4
  lda $b10
  and #$f0
  ora #$d
  sta $b10
  lda $b11
  and #$f0
  ora #$d
  sta $b11
  lda $b19
  and #$f0
  sta $b19
  lda $b1a
  and #$f0
  sta $b1a
  lda $b1b
  and #$f0
  sta $b1b
  lda $b22
  and #$f0
  sta $b22
  lda $835
  and #$f0
  ora #$d
  sta $835
  lda $83a
  and #$f0
  ora #$d
  sta $83a
  lda $83e
  and #$f0
  ora #$d
  sta $83e
  lda $846
  and #$f0
  ora #$d
  sta $846
  lda $a2a
  and #$f0
  sta $a2a
  lda $a2b
  and #$f0
  sta $a2b
  lda $a2c
  and #$f0
  sta $a2c
  lda $a2d
  and #$f0
  sta $a2d
  lda $a2e
  and #$f0
  sta $a2e
  lda $a2f
  and #$f0
  sta $a2f
  lda $a30
  and #$f0
  sta $a30
  lda $a31
  and #$f0
  sta $a31
  lda $a33
  and #$f0
  ora #$b
  sta $a33
  lda $a3a
  and #$f0
  sta $a3a
  lda $ab5
  and #$f0
  ora #$b
  sta $ab5
  lda $ab8
  and #$f0
  sta $ab8
  lda $869
  and #$f0
  ora #$c
  sta $869
  lda $9e8
  and #$f0
  ora #$c
  sta $9e8
  lda $a6a
  and #$f0
  ora #$c
  sta $a6a
  lda $a73
  and #$f0
  sta $a73
  ; odd bytes
  lda $993
  and #$0f
  ora #$d0
  sta $993
  lda $99c
  and #$0f
  sta $99c
  lda $9a6
  and #$0f
  sta $9a6
  lda $a90
  and #$0f
  ora #$d0
  sta $a90
  lda $a91
  and #$0f
  ora #$d0
  sta $a91
  lda $a9b
  and #$0f
  sta $a9b
  lda $aa1
  and #$0f
  ora #$d0
  sta $aa1
  lda $b14
  and #$0f
  sta $b14
  lda $b1f
  and #$0f
  ora #$d0
  sta $b1f
  lda $b81
  and #$0f
  ora #$b0
  sta $b81
  lda $b82
  and #$0f
  ora #$b0
  sta $b82
  lda $b99
  and #$0f
  ora #$d0
  sta $b99
  lda $b9a
  and #$0f
  ora #$d0
  sta $b9a
  lda $b9b
  and #$0f
  ora #$d0
  sta $b9b
  lda $ba1
  and #$0f
  ora #$d0
  sta $ba1
  lda $ba2
  and #$0f
  ora #$d0
  sta $ba2
  lda $ba3
  and #$0f
  ora #$d0
  sta $ba3
  lda $ba4
  and #$0f
  ora #$d0
  sta $ba4
  lda $ba5
  and #$0f
  ora #$d0
  sta $ba5
  lda $8b5
  and #$0f
  ora #$b0
  sta $8b5
  lda $8b6
  and #$0f
  ora #$b0
  sta $8b6
  lda $8b7
  and #$0f
  ora #$b0
  sta $8b7
  lda $933
  and #$0f
  ora #$b0
  sta $933
  lda $939
  and #$0f
  ora #$b0
  sta $939
  lda $9b1
  and #$0f
  sta $9b1
  lda $a36
  and #$0f
  ora #$b0
  sta $a36
  lda $a37
  and #$0f
  ora #$b0
  sta $a37
  lda $a4d
  and #$0f
  sta $a4d
  lda $bcb
  and #$0f
  ora #$c0
  sta $bcb
  lda $96b
  and #$0f
  ora #$c0
  sta $96b
  lda $971
  and #$0f
  ora #$c0
  sta $971
  rts
