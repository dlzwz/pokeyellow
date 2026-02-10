TryFieldMove:: ; predef
	call GetPredefRegisters
	call TrySurf
	ret z
	call TryCut
	ret

TrySurf:
	ld a, [wWalkBikeSurfState]
	cp 2 ; is the player already surfing?
	jr z, .no
	farcall IsNextTileShoreOrWater
	jr nc, .no
	ld hl, TilePairCollisionsWater
	call CheckForTilePairCollisions2
	jr c, .no
	ld d, HM_SURF
	call HasHMInBag
	jr nc, .no
	ld d, SURF
	call HasPartyMove
	jr nz, .no
	ld a, [wObtainedBadges]
	bit 4, a ; SOUL BADGE
	jr z, .no
	farcall IsSurfingAllowed
	ld hl, wStatusFlags1
	bit BIT_SURF_ALLOWED, [hl]
	res BIT_SURF_ALLOWED, [hl]
	jr z, .no2
	call InitializeFieldMoveTextBox
	ld hl, PromptToSurfText
	call PrintText
	call YesNoChoice
	ld a, [wCurrentMenuItem]
	and a
	jr nz, .no2
	call GetPartyMonName2
	ld a, SURFBOARD
	ld [wCurItem], a
	ld [wPseudoItemID], a
	call UseItem
.yes2
	call CloseFieldMoveTextBox
.yes
	xor a
	ret
.no2
	call CloseFieldMoveTextBox
.no
	ld a, 1
	and a
	ret

TryCut:
	call IsCutTile
	jr nc, TrySurf.no
	ld d, HM_CUT
	call HasHMInBag
	jr nc, TrySurf.no
	call InitializeFieldMoveTextBox
	ld hl, ExplainCutText
	call PrintText
	call ManualTextScroll
	ld d, CUT
	call HasPartyMove
	jr nz, TrySurf.no2
	ld a, [wObtainedBadges]
	bit 1, a ; CASCADE BADGE
	jr z, TrySurf.no2
	ld hl, PromptToCutText
	call PrintText
	call YesNoChoice
	ld a, [wCurrentMenuItem]
	and a
	jr nz, TrySurf.no2
	call GetPartyMonName2
	farcall Cut2
	call CloseFieldMoveTextBox
	jr TrySurf.yes2

IsCutTile:
; partial copy from UsedCut
	ld a, [wCurMapTileset]
	and a ; OVERWORLD
	jr z, .overworld
	cp GYM
	jr nz, .no
	ld a, [wTileInFrontOfPlayer]
	cp $50 ; gym cut tree
	jr nz, .no
	jr .yes
.overworld
	ld a, [wTileInFrontOfPlayer]
	cp $3d ; cut tree
	jr nz, .no
.yes
	scf
	ret
.no
	and a
	ret

HasHMInBag::
; Input: d = item ID to search for
; Output: carry set if found, carry clear if not
; Preserves: bc, de
	ld hl, wBagItems
.loop
	ld a, [hli]
	cp $ff
	jr z, .notFound
	cp d
	jr nz, .next
	scf
	ret
.next
	inc hl
	jr .loop
.notFound
	and a
	ret

HasPartyMove::
; Return z (optional: in wWhichTrade) if a PartyMon has move d.
; Also checks if a PartyMon can learn the move (eligibility).
; Updates wWhichPokemon.
	push bc
	push de
	push hl

	ld a, [wPartyCount]
	and a
	jr z, .no
	ld b, a
	ld c, 0
	ld hl, wPartyMons + (wPartyMon1Moves - wPartyMon1)
.loop
	ld e, NUM_MOVES
.check_move
	ld a, [hli]
	cp d
	jr z, .found
	dec e
	jr nz, .check_move

	ld a, wPartyMon2 - wPartyMon1 - NUM_MOVES
	add l
	ld l, a
	ld a, 0
	adc h
	ld h, a

	inc c
	ld a, c
	cp b
	jr c, .loop
	; No Pokemon knows the move, check if any can learn it
	ld a, [wPartyCount]
	ld b, a
	ld c, 0
.canLearnLoop
	ld a, c
	ld [wWhichPokemon], a
	ld a, d
	ld [wNamedObjectIndex], a
	push bc
	push de
	farcall CanLearnFieldMoveEntry
	pop de
	pop bc
	jr nc, .found
	inc c
	ld a, c
	cp b
	jr c, .canLearnLoop
.no
	ld a, 1
	and a
	ld [wWhichTrade], a
	jr .done
.found
	ld a, c
	ld [wWhichPokemon], a
	xor a
	ld [wWhichTrade], a
.done
	pop hl
	pop de
	pop bc
	ret

InitializeFieldMoveTextBox:
	call EnableAutoTextBoxDrawing
	ld a, 1 ; not 0
	ld [hSpriteIndex], a
	farcall DisplayTextIDInit
	ret

CloseFieldMoveTextBox:
	ld a,[hLoadedROMBank]
	push af
	jp CloseTextDisplay

PromptToSurfText:
	text "The water is calm."
	line "Would you like to"
	cont "SURF?@@"

ExplainCutText:
	text "This tree can be"
	line "CUT!@@"

PromptToCutText:
	text "Would you like to"
	line "use CUT?@@"
