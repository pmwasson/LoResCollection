
; Tiles



; Level Data
        
        ;; The following table give the initial position of the piece for each level
        ;; on a 7x7 grid.
        ;; (shape,x,y) * 16
        ;;
        ;; number       shape
        ;; 0            /\
        ;;              \/
        ;;
        ;; 1            ##
        ;;
        ;; 2            ###
        ;;
        ;; 3            #
        ;;              #
        ;;
        ;; 4            #
        ;;              #
        ;;              #
        ;;
        ;; 5            ##
        ;;              ##
        ;;
        ;; negative     end of list

levelTable:
        .word level_1
        .word level_2
        .word level_3
        .word level_4
        .word level_5
        .word level_6
        .word level_7
        .word level_8
        .word level_9
        .word level_10
        .word level_11
        .word level_12
        .word level_13
        .word level_14
        .word level_15
        .word level_16
        .word level_17
        .word level_18
        .word level_19
        .word level_20
        .word level_21
        .word level_22
        .word level_23
        .word level_24
        .word level_25
        .word level_26
        .word level_27
        .word level_28
        .word level_29
        .word level_30
        .word level_31
        .word level_32
        .word level_33
        .word level_34
        .word level_35
        .word level_36
        .word level_37
        .word level_38
        .word level_39
        .word level_40

level_1:
        .byte        0,2,5
        .byte        1,5,0
        .byte        1,1,1
        .byte        1,2,3
        .byte        1,4,3
        .byte        1,3,4
        .byte        1,5,4
        .byte        3,1,2
        .byte        3,6,2
        .byte        4,3,0
        .byte        5,5,5
        .byte        $FF,0,0

level_2:
        .byte        0,4,2
        .byte        5,0,1
        .byte        2,3,1
        .byte        4,6,1
        .byte        4,3,2
        .byte        4,0,3
        .byte        1,1,3
        .byte        3,1,4
        .byte        3,2,4
        .byte        2,4,4
        .byte        1,4,5
        .byte        $FF,0,0

level_3:
        .byte        0,0,4
        .byte        4,3,0
        .byte        5,4,1
        .byte        3,0,2
        .byte        3,3,3
        .byte        1,5,4
        .byte        1,2,5
        .byte        1,4,5
        .byte        1,1,6
        .byte        1,3,6
        .byte        $FF,0,0

level_4:
        .byte        0,4,3
        .byte        3,1,0
        .byte        2,2,0
        .byte        4,5,0
        .byte        3,3,1
        .byte        5,0,2
        .byte        1,2,3
        .byte        4,0,4
        .byte        3,2,4
        .byte        3,4,5
        .byte        2,1,6
        .byte        $FF,0,0

level_5:
        .byte        0,1,3
        .byte        3,3,1
        .byte        1,0,2
        .byte        1,5,2
        .byte        5,3,3
        .byte        3,5,3
        .byte        1,0,5
        .byte        3,3,5
        .byte        1,5,5
        .byte        $FF,0,0

level_6:
        .byte        0,1,5
        .byte        4,1,2
        .byte        3,2,2
        .byte        1,3,2
        .byte        4,5,2
        .byte        1,3,3
        .byte        2,2,4
        .byte        2,3,5
        .byte        $FF,0,0

level_7:
        .byte        0,0,4
        .byte        5,1,0
        .byte        1,4,0
        .byte        3,0,1
        .byte        3,3,1
        .byte        3,6,1
        .byte        1,1,3
        .byte        1,4,3
        .byte        3,3,4
        .byte        3,6,4
        .byte        5,4,5
        .byte        1,1,6
        .byte        $FF,0,0

level_8:
        .byte        0,0,0
        .byte        2,3,0
        .byte        5,3,1
        .byte        1,1,2
        .byte        1,5,2
        .byte        4,3,3
        .byte        4,4,3
        .byte        1,2,6
        .byte        1,4,6
        .byte        $FF,0,0

level_9:
        .byte        0,2,3
        .byte        3,3,0
        .byte        3,2,1
        .byte        4,4,1
        .byte        3,1,2
        .byte        3,5,2
        .byte        1,0,4
        .byte        3,4,4
        .byte        1,5,4
        .byte        3,2,5
        .byte        1,3,6
        .byte        $FF,0,0

level_10:
        .byte        0,0,5
        .byte        3,3,1
        .byte        1,4,1
        .byte        4,2,2
        .byte        3,5,2
        .byte        4,6,2
        .byte        1,3,3
        .byte        3,3,4
        .byte        5,4,4
        .byte        $FF,0,0

level_11:
        .byte        0,0,4
        .byte        3,2,0
        .byte        3,5,2
        .byte        3,2,4
        .byte        5,0,0
        .byte        5,3,2
        .byte        2,0,2
        .byte        2,3,4
        .byte        2,0,6
        .byte        $FF,0,0

level_12:
        .byte        0,2,2
        .byte        5,3,0
        .byte        3,5,1
        .byte        5,0,3
        .byte        2,4,3
        .byte        4,3,4
        .byte        1,5,4
        .byte        1,1,5
        .byte        3,4,5
        .byte        $FF,0,0

level_13:
        .byte        0,1,1
        .byte        2,0,0
        .byte        1,4,0
        .byte        4,4,1
        .byte        3,6,1
        .byte        2,1,3
        .byte        3,6,3
        .byte        3,3,4
        .byte        5,4,4
        .byte        3,0,5
        .byte        1,2,6
        .byte        2,4,6
        .byte        $FF,0,0

level_14:
        .byte        0,1,3
        .byte        1,0,0
        .byte        1,3,0
        .byte        3,5,1
        .byte        4,0,2
        .byte        2,1,2
        .byte        4,3,3
        .byte        3,5,4
        .byte        2,0,5
        .byte        $FF,0,0

level_15:
        .byte        0,1,5
        .byte        1,0,0
        .byte        1,2,0
        .byte        5,1,1
        .byte        3,6,1
        .byte        3,0,2
        .byte        4,4,2
        .byte        1,1,3
        .byte        4,3,3
        .byte        3,5,3
        .byte        4,6,3
        .byte        3,0,4
        .byte        5,4,5
        .byte        $FF,0,0

level_16:
        .byte        0,0,4
        .byte        1,1,0
        .byte        1,3,0
        .byte        1,2,1
        .byte        1,1,2
        .byte        5,3,2
        .byte        1,0,3
        .byte        4,2,3
        .byte        4,5,3
        .byte        1,3,4
        .byte        3,3,5
        .byte        3,4,5
        .byte        1,1,6
        .byte        $FF,0,0

level_17:
        .byte        0,0,5
        .byte        2,0,1
        .byte        3,3,1
        .byte        4,0,2
        .byte        5,1,2
        .byte        1,3,3
        .byte        1,1,4
        .byte        2,3,4
        .byte        2,2,5
        .byte        3,5,5
        .byte        3,6,5
        .byte        1,3,6
        .byte        $FF,0,0

level_18:
        .byte        0,1,2
        .byte        3,0,0
        .byte        3,3,0
        .byte        5,5,0
        .byte        1,1,1
        .byte        2,3,3
        .byte        3,6,3
        .byte        2,3,4
        .byte        5,0,5
        .byte        3,3,5
        .byte        3,6,5
        .byte        $FF,0,0

level_19:
        .byte        0,1,5
        .byte        3,0,0
        .byte        2,1,1
        .byte        2,0,2
        .byte        1,3,2
        .byte        1,1,4
        .byte        2,3,4
        .byte        3,0,5
        .byte        3,3,5
        .byte        5,4,5
        .byte        3,6,5
        .byte        $FF,0,0

level_20:
        .byte        0,4,4
        .byte        5,5,0
        .byte        3,1,1
        .byte        1,2,1
        .byte        4,3,2
        .byte        2,0,3
        .byte        4,6,3
        .byte        3,3,5
        .byte        1,0,6
        .byte        2,4,6
        .byte        $FF,0,0

level_21:
        .byte        0,2,5
        .byte        5,2,0
        .byte        1,5,1
        .byte        3,0,2
        .byte        3,1,2
        .byte        1,2,2
        .byte        5,4,2
        .byte        4,6,2
        .byte        3,2,3
        .byte        3,3,3
        .byte        1,0,4
        .byte        1,4,4
        .byte        1,5,5
        .byte        $FF,0,0

level_22:
        .byte        0,1,5
        .byte        2,1,1
        .byte        3,4,1
        .byte        3,1,2
        .byte        5,2,2
        .byte        4,0,3
        .byte        1,4,3
        .byte        1,1,4
        .byte        3,3,4
        .byte        1,4,4
        .byte        3,6,4
        .byte        5,4,5
        .byte        $FF,0,0

level_23:
        .byte        0,5,5
        .byte        3,1,0
        .byte        5,2,0
        .byte        1,4,0
        .byte        4,6,0
        .byte        4,5,1
        .byte        4,4,2
        .byte        4,3,3
        .byte        4,2,4
        .byte        3,1,5
        .byte        1,3,6
        .byte        $FF,0,0

level_24:
        .byte        0,1,2
        .byte        3,4,0
        .byte        1,5,0
        .byte        4,0,1
        .byte        2,1,1
        .byte        3,6,1
        .byte        4,3,2
        .byte        1,4,2
        .byte        5,4,3
        .byte        2,0,4
        .byte        5,0,5
        .byte        3,4,5
        .byte        3,5,5
        .byte        $FF,0,0

level_25:
        .byte        0,2,2
        .byte        3,1,0
        .byte        3,2,0
        .byte        3,5,0
        .byte        1,3,1
        .byte        5,0,2
        .byte        5,5,2
        .byte        3,1,4
        .byte        3,2,4
        .byte        1,3,4
        .byte        3,5,4
        .byte        $FF,0,0

level_26:
        .byte        0,0,0
        .byte        5,5,0
        .byte        2,2,1
        .byte        4,1,2
        .byte        3,4,2
        .byte        1,5,2
        .byte        1,2,4
        .byte        1,5,4
        .byte        5,0,5
        .byte        3,2,5
        .byte        3,4,5
        .byte        $FF,0,0

level_27:
        .byte        0,1,3
        .byte        4,2,0
        .byte        2,3,0
        .byte        3,1,1
        .byte        1,3,1
        .byte        5,5,1
        .byte        5,3,2
        .byte        4,5,3
        .byte        3,6,3
        .byte        1,3,4
        .byte        2,2,5
        .byte        $FF,0,0

level_28:
        .byte        0,0,0
        .byte        2,2,0
        .byte        5,2,1
        .byte        2,4,1
        .byte        4,0,2
        .byte        5,4,2
        .byte        3,1,3
        .byte        4,2,3
        .byte        3,3,4
        .byte        4,4,4
        .byte        1,0,5
        .byte        3,5,5
        .byte        1,2,6
        .byte        $FF,0,0

level_29:
        .byte        0,2,2
        .byte        5,0,0
        .byte        1,2,0
        .byte        4,4,0
        .byte        1,2,1
        .byte        1,0,2
        .byte        1,0,3
        .byte        1,4,3
        .byte        2,0,4
        .byte        3,3,4
        .byte        5,4,4
        .byte        3,6,5
        .byte        1,0,6
        .byte        $FF,0,0

level_30:
        .byte        0,0,2
        .byte        1,2,1
        .byte        3,4,1
        .byte        3,2,2
        .byte        5,5,2
        .byte        1,3,3
        .byte        4,1,4
        .byte        2,2,4
        .byte        4,5,4
        .byte        2,2,5
        .byte        2,2,6
        .byte        $FF,0,0

level_31:
        .byte        0,0,5
        .byte        2,0,0
        .byte        3,4,0
        .byte        3,0,1
        .byte        4,2,1
        .byte        1,5,2
        .byte        5,0,3
        .byte        2,3,4
        .byte        4,6,4
        .byte        5,2,5
        .byte        1,4,6
        .byte        $FF,0,0

level_32:
        .byte        0,0,1
        .byte        4,3,0
        .byte        2,4,0
        .byte        5,4,1
        .byte        4,6,1
        .byte        1,0,3
        .byte        2,3,3
        .byte        2,1,4
        .byte        3,2,5
        .byte        $FF,0,0

level_33:
        .byte        0,2,2
        .byte        4,0,0
        .byte        3,2,0
        .byte        3,3,0
        .byte        4,5,0
        .byte        1,0,3
        .byte        1,4,3
        .byte        1,0,4
        .byte        5,2,4
        .byte        1,4,4
        .byte        1,2,6
        .byte        $FF,0,0

level_34:
        .byte        0,0,3
        .byte        3,0,0
        .byte        1,1,0
        .byte        5,3,0
        .byte        3,2,1
        .byte        4,5,1
        .byte        1,0,2
        .byte        1,3,2
        .byte        4,6,2
        .byte        3,2,3
        .byte        5,3,3
        .byte        2,1,5
        .byte        2,2,6
        .byte        $FF,0,0

level_35:
        .byte        0,0,4
        .byte        3,0,0
        .byte        3,1,0
        .byte        5,2,0
        .byte        3,4,0
        .byte        3,5,0
        .byte        1,0,2
        .byte        5,4,2
        .byte        1,0,3
        .byte        3,2,4
        .byte        3,3,4
        .byte        1,4,4
        .byte        1,4,5
        .byte        $FF,0,0

level_36:
        .byte        0,0,4
        .byte        3,3,0
        .byte        2,4,0
        .byte        5,5,1
        .byte        1,2,2
        .byte        3,4,2
        .byte        1,0,3
        .byte        3,2,3
        .byte        1,5,3
        .byte        1,3,4
        .byte        4,6,4
        .byte        3,3,5
        .byte        5,4,5
        .byte        2,0,6
        .byte        $FF,0,0

level_37:
        .byte        0,3,5
        .byte        1,0,0
        .byte        1,5,0
        .byte        5,0,1
        .byte        4,3,1
        .byte        2,4,2
        .byte        4,5,3
        .byte        3,0,4
        .byte        2,2,4
        .byte        1,0,6
        .byte        $FF,0,0

level_38:
        .byte        0,1,0
        .byte        3,0,0
        .byte        3,4,0
        .byte        1,5,0
        .byte        4,3,1
        .byte        3,6,1
        .byte        3,2,2
        .byte        1,4,2
        .byte        4,1,3
        .byte        1,4,3
        .byte        3,0,4
        .byte        2,2,4
        .byte        5,5,4
        .byte        1,2,5
        .byte        2,0,6
        .byte        1,5,6
        .byte        $FF,0,0

level_39:
        .byte        0,1,1
        .byte        1,1,0
        .byte        3,3,0
        .byte        3,4,0
        .byte        3,5,0
        .byte        3,6,0
        .byte        3,0,1
        .byte        4,5,2
        .byte        1,0,3
        .byte        1,0,4
        .byte        5,0,5
        .byte        2,2,5
        .byte        5,5,5
        .byte        $FF,0,0

level_40:
        .byte        0,4,3
        .byte        3,3,0
        .byte        4,4,0
        .byte        4,2,1
        .byte        3,5,1
        .byte        3,1,2
        .byte        3,3,2
        .byte        3,6,2
        .byte        3,0,3
        .byte        5,2,4
        .byte        4,6,4
        .byte        3,0,5
        .byte        5,4,5
        .byte        1,2,6
        .byte        $FF,0,0

