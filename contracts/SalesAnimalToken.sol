// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "MintAnimalToken.sol";

contract SaleAnimalToken {
    MintAnimalToken public mintAnimalTokenAddress;

     constructor (address _mintAnimalTokenAddress) {
        mintAnimalTokenAddress = MintAnimalToken(_mintAnimalTokenAddress);
    }

    // 가격들을 관리하는 매핑
    // anmialTokenId -> 출력 : 가격
    mapping (uint256 => uint256) public animalTokenPrices;

    // 프론트엔드에서 배열을 가지고 판매 중인 토큰인지 확인할 수 있도록
    uint256[] public onSaleAnimalTokenArray;

    // ****판매 등록 함수****

    // 인자값 : 토큰ID , 가격
    function setForSaleAnimalToken(uint256 _animalTokenId, uint256 _price) public {
        // ownerOf -> 토큰Id값으로 주인을 찾아오는 것 
        address animalTokenOwner = mintAnimalTokenAddress.ownerOf(_animalTokenId);

        // 1. 주인이 맞는 지 확인
        // 틀렸을 경우 'Caller is not animal token owner.' 에러 메세지를 반환
        require(animalTokenOwner == msg.sender, "Caller is not animal token owner.");  
        
        // 2. 금액 확인
        require(_price > 0, "Price is zero or lower.");
        
        
        // 3. 값이 있거나 0원 인 경우
        // 0원이 아닌 경우 이미 판매 등록이 완료됬다는 이미?니깐 alreay on sale
        require(animalTokenPrices[_animalTokenId] == 0, "This animal token is already on sale");

        // 4. animalTokenOwner가 판매 계약서(address(this))에 권한을 다 넘겼는지 확인하는 것 
        require(mintAnimalTokenAddress.isApprovedForAll(animalTokenOwner, address(this)), "Animal token owner did not approve token.");

        animalTokenPrices[_animalTokenId] = _price;
        onSaleAnimalTokenArray.push(_animalTokenId);
        
    }

    // ****구매 등록 함수****
    function purchaseAnimalToken(uint256 _animalTokenId) public payable {
        uint256 price = animalTokenPrices[_animalTokenId];
        address animalTokenOwner = mintAnimalTokenAddress.ownerOf(_animalTokenId); // 주인의 주소값을 가져오기

        // 1. 구매 금액이 0보다 커야 판매 중이라는 것이기 때문
        require(price > 0 ,"Animal token not sale.");

        // 2. msg.value (보내는 금액의 양)이 price보다 커야 구매가 가능
        require(price <= msg.value, "Caller sent lower then price.");

        // 3. 구매 할 때는, 주인이 아니여야만 구매가 가능
        require(animalTokenOwner != msg.sender, "Caller is aniaml token owner.");



        // 가격만큼 주인에게 전송시켜주는 기능 , 반대로 NFT 카드는 지불한 사람에게 전송해주기
        payable(animalTokenOwner).transfer(msg.value);

        // 보내는 사람, 받는 사람, 무엇을 보낼 것인지
        mintAnimalTokenAddress.safeTransferFrom(animalTokenOwner, msg.sender, _animalTokenId); 
    
        // mapping에서 다시 삭제 시켜주기 (가격 초기화)
        animalTokenPrices[_animalTokenId] = 0;

        // 판매중인 개수 만큼 for문 돌려주기
        for(uint256 i = 0; i < onSaleAnimalTokenArray.length; i++){

            // 판매 한 것만 0원으로 초기화 시켜줬기 때문에
            // 나머지 상품은 가격이 존재할 수 있음.
            // 가격이 0원인 제품을 찾아서 제거 
            if(animalTokenPrices[onSaleAnimalTokenArray[i]] == 0 ) {
                // 현재 가격이 0원인 것이랑 맨 뒤 제품이랑 자리 교체하고
                // pop()으로 맨 뒤에 있는거 지워주는 로직
                onSaleAnimalTokenArray[i] = onSaleAnimalTokenArray[onSaleAnimalTokenArray.length - 1];
                onSaleAnimalTokenArray.pop();
            }
        }

    }

    // 판매 중인 토큰 배열의 길이를 구하는 함수 
    function getOnSaleAnimalTokenArrayLength() view public returns (uint256) {
        return onSaleAnimalTokenArray.length;
    }

}