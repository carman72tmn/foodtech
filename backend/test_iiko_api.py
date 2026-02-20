import httpx
import asyncio

async def test_auth():
    api_login = "86dfd64bd15c42199b789edf6adcb289"
    url = "https://api-ru.iiko.services/api/1/access_token"
    
    print(f"Testing API Login: {api_login}")
    try:
        async with httpx.AsyncClient() as client:
            response = await client.post(url, json={"apiLogin": api_login}, timeout=10.0)
            print(f"Status: {response.status_code}")
            print(f"Response: {response.text}")
    except Exception as e:
        print(f"Error: {str(e)}")

if __name__ == "__main__":
    asyncio.run(test_auth())
