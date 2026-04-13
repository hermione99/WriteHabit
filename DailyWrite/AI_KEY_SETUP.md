# AI Keyword Generation Setup

To enable AI-powered endless keyword generation:

## 1. Get OpenAI API Key

1. Go to https://platform.openai.com/api-keys
2. Sign up or log in
3. Click "Create new secret key"
4. Copy the key (starts with `sk-...`)

## 2. Add API Key to Project

Open `DailyWrite/Services/AIKeywordService.swift` and replace:

```swift
private let openAIKey = "YOUR_OPENAI_API_KEY"
```

with your actual key:

```swift
private let openAIKey = "sk-your-actual-key-here"
```

## 3. How It Works

- App starts with 40 default keywords (20 Korean + 20 English)
- When keywords run low, AI automatically generates 30 new ones
- Keywords are cached locally for offline use
- Each user gets consistent daily keywords based on the date
- Costs ~$0.01-0.02 per month (30 keywords ≈ 500 tokens ≈ $0.0075)

## 4. Privacy

- Keywords are generated via OpenAI API
- No personal data is sent to OpenAI
- Only the prompt ("Generate 30 unique writing prompts...") is sent
- Keywords are stored locally on the device

## 5. Troubleshooting

If keywords aren't generating:
1. Check your API key is correct
2. Ensure you have credits on OpenAI
3. Check console for error messages
4. The app will fallback to default keywords if AI fails
