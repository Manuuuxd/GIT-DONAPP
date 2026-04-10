# llm.py
import os, time, requests, json

RUNPOD_API_KEY = os.getenv("RUNPOD_API_KEY")
MAX_RETRIES = int(os.getenv("RUNPOD_MAX_RETRIES","20"))
WAIT_SECONDS = float(os.getenv("RUNPOD_WAIT_SECONDS","1.5"))

def _headers():
    return {"Authorization": f"Bearer {RUNPOD_API_KEY}", "Content-Type": "application/json"}

def _safe_json(resp: requests.Response):
    try:
        return resp.json()
    except Exception:
        return {"_raw_text": resp.text, "_status": resp.status_code}

def _runsync(endpoint_id: str, prompt: str, system: str | None):
    url = f"https://api.runpod.ai/v2/{endpoint_id}/runsync"
    payload = {"input": {"prompt": prompt}}
    if system: payload["input"]["system"] = system
    r = requests.post(url, headers=_headers(), json=payload, timeout=120)

    data = _safe_json(r)
    if r.status_code != 200:
        # devuelve algo legible en vez de ValueError
        return {"status": "FAILED", "text": "", "raw": data, "error": f"RunPod {r.status_code}"}

    out = (data.get("output") or {})
    text = out.get("response") or out.get("content") or (out if isinstance(out, str) else "")
    return {"status": data.get("status") or "COMPLETED", "text": text, "raw": data}

def _run_async_and_poll(endpoint_id: str, prompt: str, system: str | None):
    run_url = f"https://api.runpod.ai/v2/{endpoint_id}/run"
    payload = {"input": {"prompt": prompt}}
    if system: payload["input"]["system"] = system
    launch = requests.post(run_url, headers=_headers(), json=payload, timeout=30)
    launch_j = _safe_json(launch)
    req_id = launch_j.get("id")
    if not req_id:
        return {"status":"FAILED","error":"RunPod no devolvió ID","raw":launch_j}

    status_url = f"https://api.runpod.ai/v2/{endpoint_id}/status/{req_id}"
    for _ in range(MAX_RETRIES):
        st_resp = requests.get(status_url, headers=_headers(), timeout=30)
        st = _safe_json(st_resp)
        status = st.get("status")
        if status == "COMPLETED":
            out = (st.get("output") or {})
            text = out.get("response") or out.get("content") or (out if isinstance(out, str) else "")
            return {"status":"COMPLETED","text":text,"raw":st}
        if status in ("FAILED","CANCELLED"):
            return {"status":status,"error":"Ejecución fallida","raw":st}
        time.sleep(WAIT_SECONDS)
    return {"status":"IN_PROGRESS","id":req_id}

def ask_model(prompt: str, system: str | None = None, endpoint_id: str | None = None, sync: bool = True):
    if sync: return _runsync(endpoint_id, prompt, system)
    return _run_async_and_poll(endpoint_id, prompt, system)
