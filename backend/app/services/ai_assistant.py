"""
AI Travel Assistant Service
Egypt-specialized AI with safety focus for solo travelers, women, and people with disabilities
"""
from openai import OpenAI
from typing import Optional, Dict, List
import uuid
from datetime import datetime
from app.config import settings


class AIAssistantService:
    """
    Egypt-specialized AI travel assistant service
    Provides safety-focused travel advice with context awareness
    """
    
    def __init__(self):
        """Initialize OpenAI client and conversation storage"""
        self.client = OpenAI(api_key=settings.OPENAI_API_KEY)
        # TODO: Replace with Redis or database in production
        self.conversations = {}  # In-memory storage for development
        
        # Egypt-specialized system prompt
        self.system_prompt = """You are an expert AI travel assistant specializing in Egypt tourism with a strong emphasis on safety and accessibility.

Your primary focus areas:
1. **Safety First**: Always prioritize traveler safety in recommendations
2. **Cultural Sensitivity**: Respect Egyptian customs and Islamic traditions
3. **Gender Awareness**: Provide specific guidance for women travelers (dress codes, safe transportation, women-only areas)
4. **Solo Travel Support**: Extra safety tips for solo travelers
5. **Accessibility**: Consider wheelchair access, visual/hearing impairments, mobility needs
6. **Scam Prevention**: Warn about common tourist scams and how to avoid them
7. **Emergency Preparedness**: Provide relevant emergency contacts and procedures

When responding:
- Be specific, practical, and actionable
- Include safety considerations in every recommendation
- Mention accessibility when relevant
- Suggest official/licensed services over informal ones
- Warn about areas or situations to avoid
- Provide cultural context to help travelers understand local norms
- Maintain a friendly, reassuring, and helpful tone

Special considerations:
- Women travelers: Emphasize conservative dress, safe areas, women-only transportation options
- Solo travelers: Recommend group tours, safe neighborhoods, buddy systems
- Accessibility needs: Verify wheelchair access, suggest accessible alternatives
- First-time visitors: Provide extra cultural orientation and practical tips"""

    def _build_messages(
        self, 
        user_message: str, 
        conversation_id: Optional[str] = None,
        user_context: Optional[Dict] = None
    ) -> List[Dict]:
        """
        Build complete message array with system prompt, context, and history
        
        Args:
            user_message: Current user message
            conversation_id: Optional conversation ID for history
            user_context: Optional user context dict
            
        Returns:
            List of message dicts for OpenAI API
        """
        messages = [{"role": "system", "content": self.system_prompt}]
        
        # Add user-specific context if provided
        if user_context:
            context_prompt = self._build_context_prompt(user_context)
            if context_prompt:
                messages.append({"role": "system", "content": context_prompt})
        
        # Add conversation history if exists
        if conversation_id and conversation_id in self.conversations:
            # Add last 10 messages for context (prevent token overflow)
            history = self.conversations[conversation_id][-10:]
            messages.extend(history)
        
        # Add current user message
        messages.append({"role": "user", "content": user_message})
        
        return messages

    def _build_context_prompt(self, user_context: Dict) -> str:
        """
        Build additional context prompt based on user profile
        
        Args:
            user_context: Dict with gender, traveling_alone, accessibility_needs, etc.
            
        Returns:
            Context prompt string
        """
        context_parts = ["IMPORTANT - User-specific context:"]
        
        # Gender-specific considerations
        if user_context.get("gender") == "female":
            context_parts.append(
                "- FEMALE TRAVELER: Prioritize women's safety. Include dress code advice, "
                "women-only transportation, safe areas for solo women, and scam awareness."
            )
        
        # Solo travel considerations
        if user_context.get("traveling_alone"):
            context_parts.append(
                "- SOLO TRAVELER: Emphasize solo safety tips, recommend group tours, "
                "suggest safe accommodations, and provide emergency protocols."
            )
        
        # Accessibility needs
        if user_context.get("accessibility_needs"):
            needs = user_context["accessibility_needs"]
            if isinstance(needs, list):
                needs_str = ", ".join(needs)
            else:
                needs_str = str(needs)
            context_parts.append(
                f"- ACCESSIBILITY NEEDS: {needs_str}. CRITICAL: Verify accessibility "
                f"for ALL recommendations. Suggest accessible alternatives."
            )
        
        # First-time visitor
        if user_context.get("first_time_egypt"):
            context_parts.append(
                "- FIRST-TIME VISITOR: Provide extra cultural orientation, "
                "explain customs, and give practical first-timer tips."
            )
        
        # Language preferences
        if user_context.get("languages"):
            langs = user_context["languages"]
            context_parts.append(
                f"- LANGUAGES: Traveler speaks {langs}. Suggest resources in these languages."
            )
        
        return "\n".join(context_parts) if len(context_parts) > 1 else ""

    def _generate_suggestions(self, user_message: str, assistant_response: str) -> List[str]:
        """
        Generate contextual follow-up question suggestions
        
        Args:
            user_message: Original user message
            assistant_response: AI's response
            
        Returns:
            List of 3 suggested follow-up questions
        """
        message_lower = user_message.lower()
        
        # Airport-related questions
        if any(word in message_lower for word in ["airport", "arrival", "landing", "flight"]):
            return [
                "How do I get from the airport to my hotel safely?",
                "What's the best way to exchange currency at the airport?",
                "Do I need a visa on arrival?"
            ]
        
        # Accommodation questions
        if any(word in message_lower for word in ["hotel", "stay", "accommodation", "hostel"]):
            return [
                "What are the safest areas to stay in Cairo?",
                "How can I avoid hotel scams?",
                "What safety features should I look for in accommodation?"
            ]
        
        # Pyramids/Giza questions
        if any(word in message_lower for word in ["pyramid", "giza", "sphinx"]):
            return [
                "What's the best time to visit the pyramids?",
                "How do I avoid scams at the pyramids?",
                "Is the pyramid area wheelchair accessible?"
            ]
        
        # Food/dining questions
        if any(word in message_lower for word in ["food", "eat", "restaurant", "dish"]):
            return [
                "What Egyptian dishes should I try?",
                "How can I avoid food poisoning?",
                "Are there good vegetarian options in Egypt?"
            ]
        
        # Transportation questions
        if any(word in message_lower for word in ["taxi", "uber", "transport", "metro", "bus"]):
            return [
                "What's the safest way to get around Cairo?",
                "Are Uber/Careem safe in Egypt?",
                "Is the Cairo Metro safe for tourists?"
            ]
        
        # Safety/scam questions
        if any(word in message_lower for word in ["safe", "scam", "danger", "avoid"]):
            return [
                "What are the most common tourist scams in Egypt?",
                "Which areas should I avoid at night?",
                "What emergency numbers should I know?"
            ]
        
        # Default suggestions
        return [
            "What are the top safety tips for traveling in Egypt?",
            "Tell me about Egyptian cultural norms I should know",
            "What are common tourist scams and how do I avoid them?"
        ]

    async def chat(
        self, 
        message: str, 
        conversation_id: Optional[str] = None,
        user_context: Optional[Dict] = None
    ) -> Dict:
        """
        Main chat function - processes user message and returns AI response
        
        Args:
            message: User's message
            conversation_id: Optional conversation ID for context
            user_context: Optional user context (gender, disabilities, etc.)
            
        Returns:
            Dict with: message, conversation_id, suggestions, timestamp
            
        Raises:
            Exception: If OpenAI API call fails
        """
        try:
            # Generate or use existing conversation ID
            conv_id = conversation_id or f"conv_{uuid.uuid4().hex[:12]}"
            
            # Build complete message array
            messages = self._build_messages(message, conversation_id, user_context)
            
            # Call OpenAI API
            response = self.client.chat.completions.create(
                model=settings.AI_MODEL,
                messages=messages,
                temperature=settings.AI_TEMPERATURE,
                max_tokens=settings.AI_MAX_TOKENS
            )
            
            # Extract assistant response
            assistant_message = response.choices[0].message.content
            
            # Store conversation in memory (replace with DB in production)
            if conv_id not in self.conversations:
                self.conversations[conv_id] = []
            
            # Add messages to history
            self.conversations[conv_id].append({"role": "user", "content": message})
            self.conversations[conv_id].append({"role": "assistant", "content": assistant_message})
            
            # Keep only last 10 messages to prevent token overflow
            if len(self.conversations[conv_id]) > 10:
                self.conversations[conv_id] = self.conversations[conv_id][-10:]
            
            # Generate contextual suggestions
            suggestions = self._generate_suggestions(message, assistant_message)
            
            return {
                "message": assistant_message,
                "conversation_id": conv_id,
                "suggestions": suggestions,
                "timestamp": datetime.now()
            }
            
        except Exception as e:
            # Log error (add proper logging in production)
            print(f"Error in AI chat: {str(e)}")
            raise

    def get_conversation_history(self, conversation_id: str) -> Optional[List[Dict]]:
        """
        Get conversation history by ID
        
        Args:
            conversation_id: Conversation ID
            
        Returns:
            List of messages or None if not found
        """
        return self.conversations.get(conversation_id)

    def clear_conversation(self, conversation_id: str) -> bool:
        """
        Clear conversation history
        
        Args:
            conversation_id: Conversation ID to clear
            
        Returns:
            True if cleared, False if not found
        """
        if conversation_id in self.conversations:
            del self.conversations[conversation_id]
            return True
        return False

    def get_all_conversations(self) -> Dict[str, int]:
        """
        Get all conversation IDs and message counts
        
        Returns:
            Dict mapping conversation_id to message count
        """
        return {
            conv_id: len(messages) 
            for conv_id, messages in self.conversations.items()
        }


# Global instance (singleton pattern)
ai_assistant = AIAssistantService()