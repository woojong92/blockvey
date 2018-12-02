pragma solidity ^0.5.0;

contract SurveyFactory {
    /* survey 저장 배열 */
    Survey[] private surveys;
    
    //Survey contract 이벤트 
    //event NewSurvey();
    /* survey contract 생성 함수 */
    function createSurvey(uint16 participantsCnt, uint16 questionsCnt, uint finishTime) public {
        //msg.sender: msg.sender, participantCnt: 모집인원 , questionCnt:질의수
        //생성할 때 가격지불;
        //msg.value = (uint)(participantsCnt*questionsCnt)*50000;
        uint amount = participantsCnt*questionsCnt*50000;
        Survey survey = new Survey( msg.sender, participantsCnt,  questionsCnt, finishTime ); 
        surveys.push(survey);
        //survey.call(abi.encodeWithSignature("f(uint256)", a, b))
        address(survey).call(abi.encodeWithSignature("transfer(address,uint256)", survey, amount));
        //emit NewSurvey();
        
    }

    // surveys get 함수
    function getSurveys() public view returns (Survey[] memory) {
        return surveys;
    }
}

contract Survey {
    
    // question 구조체: 질문 하나에 대한 답
    struct Question{
        //질의문
        string questionContent;
        //질의에 대한 답
        
        uint8 answer0;
        uint8 answer1;
        uint8 answer2;
        uint8 answer3;
        uint8 answer4;
        
       //string otherAnswer;
    }
    
    // question구조체를 담는 배열
    Question[] public questions;
 
    function createQuestion(string memory content) public{
        questions.push(Question(content,0,0,0,0,0));
    }
    
    function getQuestion(uint num) public view returns(string memory, uint, uint, uint, uint, uint){
        return (questions[num].questionContent, questions[num].answer0, questions[num].answer1, questions[num].answer2, questions[num].answer3, questions[num].answer4 );
    }
    
    // manager: 컨트랙트 배포자 어드레스
    // totalParticipantsCnt: 총 모집인원
    // totalParticipantsCntCheck: 모집인원 정원 체크
    // questionsCnt: 질문의 수
    // cooldownTime: 설문조사 시간설정?
    // complete: 설문의 완료여부
    
    
    address payable private manager;
    
    struct Status{
        uint16  totalParticipantsCnt;
        bool  totalParticipantsCntCheck;
        uint16  questionsCnt;
        //맵핑된 설문조사 참가자를 접근하기 위한 카운트
        uint16 participantsCount;
        uint finishTime;
        bool complete;
    }

    Status status; 
    
    //설문조사에 참가 여부 맵핑
    mapping(address => bool) public participantsCheck;
    mapping(uint => address) public participants;
    
    
    uint public totalBalance;
    uint public dividedBalance; 
    /* Survey 컨트랙트 생성자 */
    // input  1.  msg.sender, 2.  totalparticipantsCnt, 3.  questionsCnt
    
    constructor( address payable mgr, uint16 pCnt, uint16 qCnt, uint fTime ) public payable {
        
        //require(msg.value > 0);
        manager = mgr;
        status.totalParticipantsCnt = pCnt;
        status.questionsCnt = qCnt;
        status.finishTime = fTime; // now + 설정기간// web3를 통해 주기적으로 기간 체킹 -> 마감 
        totalBalance = msg.value; //설문조사에 드는 비용
        dividedBalance = totalBalance/(uint)(status.totalParticipantsCnt) ;
    }
    
    function() external payable { }
    
    //answerQuestion 함수 
    function answerQuestions(uint qCnt, uint[] memory qa) public {
        //설문에 참여한 적이 있는가?
        require( participantsCheck[msg.sender] == false );
        
        for( uint i =0; i< qCnt; i++){
            //openjeppline          
            if( qa[i] == 0 ){
                (questions[i].answer0)++;    
                
            }else if( qa[i] == 1){
                (questions[i].answer1)++;
            
            }else if( qa[i] == 2){
                (questions[i].answer2)++;
            
            }else if( qa[i] == 3){
                (questions[i].answer3)++;
                
            }else if( qa[i] == 4){
                (questions[i].answer4)++;
            }
        }

        
        //rewarding을 통해 참가자에게 보상을 한다.
        //rewarding();
        
    }
    
    
    function answerQuestion(uint num, uint ans) public {
        //설문에 참여한 적이 있는가?
        require( participantsCheck[msg.sender] == false );
        
        if(ans == 0){
            (questions[num].answer0)++;
        }else if(ans == 1){
            (questions[num].answer1)++;
        }else if(ans == 2){
            (questions[num].answer2)++;
        }else if(ans == 3){
            (questions[num].answer3)++;
        }else if(ans == 4){
            (questions[num].answer4)++;
        }
        
    }
    
    //rewarding 함수
    function rewarding() public payable {
        // 참가자가 설문에 참여한 적이 있는가 검사
        require( participantsCheck[msg.sender] == false );
        //How?
        //1단계 이더로 제공
        //2단계 토큰화하여 토큰 제공
        //3단계 게임을 통해 몇번째 설문 참가자에 따라 로또로 추가 토큰지급
        
        // 참가자에게 보상
       msg.sender.transfer(dividedBalance);
       participate();
      
    }
    
    //참가자의 상태, 설문 참가후 참가여부 true
    function participate() public {
        participants[status.participantsCount] = msg.sender;
        participantsCheck[msg.sender] = true;
        status.participantsCount ++;
    }
    
    //설문조사의 모집기간 설정 함수?
    function completeSurvey() public{
        require( status.totalParticipantsCnt == status.participantsCount );
        require( status.finishTime <= now );
        status.complete = true;
        
        //emit CompleteSurvey(true);
    }
    
      //설문조사의 모집기간이 종료된후 모집인원을 다 못채우면 리펀드 함
    function refundBalance() private {
        manager.transfer(dividedBalance);
        // manager.call.value(dividedBalance)("refundBalance");
    }

}
