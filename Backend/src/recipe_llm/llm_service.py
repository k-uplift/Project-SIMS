import os
import json
import uuid
from typing import List, Dict
from openai import OpenAI

from server.app.schemas.recipes import RecipeRecommendRequest, RecipeRecommendResponse
from server.app.schemas.chat import ChatRequest, ChatResponse

# API 키 연동
client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

# =====================================================================
# 1. 레시피 추천 및 개인화 로직
# =====================================================================
def generate_recipe_recommendation(
    ingredients: List[str], 
    request_params: RecipeRecommendRequest
) -> RecipeRecommendResponse:
    
    cuisine_text = f"요리 종류: {request_params.cuisine}" if request_params.cuisine else "요리 종류: 상관없음"
    difficulty_text = f"난이도: {request_params.difficulty}" if request_params.difficulty else "난이도: 상관없음"
    
    system_prompt = f"""
    너는 스마트 냉장고의 친절하고 창의적인 'AI 셰프'야.
    사용자의 [보유 식재료]를 분석하여 정확히 {request_params.max_results}개의 레시피를 추천해 줘.

    [필수 규칙]
    1. [보유 식재료]에 표시된 유통기한(D-Day)이 적게 남은 재료를 무조건 최우선으로 소진해야 해.
    2. 완벽한 요리를 위해 냉장고에 없는 재료가 필요하다면, 대체 가능한 팁을 description에 자연스럽게 적어줘. 
    3. 'id' 필드는 "recipe-" 뒤에 무작위 문자열을 붙여서 생성해.
    4. 'owned_ingredients'에는 [보유 식재료] 중 이 요리에 쓴 것만 넣고, 'missing_ingredients'에는 추가로 사야 할 재료를 넣어.
    
    [사용자 요청 조건]
    - {cuisine_text}
    - {difficulty_text}
    
    [보유 식재료 (DB 연동)]
    {json.dumps(ingredients, ensure_ascii=False)}
    """

    completion = client.beta.chat.completions.parse(
        model="gpt-4o-mini",
        messages=[
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": "지금 있는 재료들로 오늘 해 먹을 수 있는 레시피 추천해 줘!"}
        ],
        response_format=RecipeRecommendResponse,
        temperature=0.7
    )
    
    return completion.choices[0].message.parsed


# =====================================================================
# 2. 챗봇 LLM 프롬프트 로직
# =====================================================================
def generate_chat_reply(
    request: ChatRequest, 
    chat_history: List[Dict[str, str]], 
    recipe_context: str = None
) -> ChatResponse:
    
    system_prompt = "너는 요리 초보자도 쉽게 이해할 수 있게 도와주는 다정한 AI 셰프 어시스턴트야."
    
    if recipe_context:
        system_prompt += f"\n\n지금 사용자는 다음 레시피를 보고 있어. 질문에 이 레시피를 참고해서 대답해줘:\n[레시피 정보]\n{recipe_context}"

    messages = [{"role": "system", "content": system_prompt}]
    
    for msg in chat_history:
        messages.append({"role": msg["role"], "content": msg["content"]})
        
    messages.append({"role": "user", "content": request.message})

    completion = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=messages,
        temperature=0.8
    )
    
    new_session_id = request.session_id if request.session_id else f"chat-{uuid.uuid4().hex[:8]}"

    return ChatResponse(
        session_id=new_session_id,
        reply=completion.choices[0].message.content
    )