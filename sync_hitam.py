import getpass
import base64
import requests
from bs4 import BeautifulSoup
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.primitives import padding

BASE_URL = "https://www.webprosindia.com/hitam/default.aspx"
ATTENDANCE_PAGE_URL = "https://www.webprosindia.com/hitam/Academics/StudentAttendance.aspx?showtype=SA"

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "Referer": BASE_URL,
    "Origin": "https://www.webprosindia.com"
}

def encrypt_webpros_password(plain_text: str) -> str:
    """
    Encrypts password using AES-128-CBC with PKCS7 padding, matching
    CryptoJS implementation in WebPros ERP (Key and IV = '8701661282118308').
    """
    key = b"8701661282118308"
    iv = b"8701661282118308"
    
    padder = padding.PKCS7(128).padder()
    padded_data = padder.update(plain_text.encode("utf-8")) + padder.finalize()
    
    cipher = Cipher(algorithms.AES(key), modes.CBC(iv))
    encryptor = cipher.encryptor()
    ciphertext = encryptor.update(padded_data) + encryptor.finalize()
    return base64.b64encode(ciphertext).decode("utf-8")

def sync_hitam():
    session = requests.Session()
    session.headers.update(HEADERS)

    print("[*] Fetching HITAM login portal tokens...")
    resp = session.get(BASE_URL)
    if resp.status_code != 200:
        print(f"[-] Failed to reach portal. Status code: {resp.status_code}")
        return

    soup = BeautifulSoup(resp.text, "html.parser")

    def get_token(name):
        tag = soup.find("input", {"id": name}) or soup.find("input", {"name": name})
        return tag["value"] if tag and tag.has_attr("value") else ""

    roll_no = input("Enter Student Roll Number / User ID: ").strip()
    password = getpass.getpass("Enter Password: ").strip()

    # Encrypt password using WebPros AES key
    encrypted_pwd = encrypt_webpros_password(password)

    # WebPros Student Login Payload (Section 2)
    payload = {
        "__VIEWSTATE": get_token("__VIEWSTATE"),
        "__VIEWSTATEGENERATOR": get_token("__VIEWSTATEGENERATOR"),
        "__EVENTVALIDATION": get_token("__EVENTVALIDATION"),
        "txtId1": "",
        "txtPwd1": "",
        "hdnpwd1": "",
        "txtId2": roll_no,
        "txtPwd2": encrypted_pwd,
        "hdnpwd2": encrypted_pwd,
        "txtId3": "",
        "txtPwd3": "",
        "hdnpwd3": "",
        "imgBtn2.x": "30",
        "imgBtn2.y": "15"
    }

    print("[*] Submitting login request...")
    login_resp = session.post(BASE_URL, data=payload, allow_redirects=False)

    if login_resp.status_code == 302 and "studentmaster" in login_resp.headers.get("Location", "").lower():
        print(f"[+] Successfully logged in! Redirected to: {login_resp.headers.get('Location')}")
    elif "ASP.NET_SessionId" in session.cookies:
        print("[+] Authentication cookie received!")
    else:
        print(f"[-] Login failed (Status: {login_resp.status_code}, Location: {login_resp.headers.get('Location')}).")
        print("[-] Please verify your Roll Number and Password.")
        return

    # Fetch attendance page to discover the dynamic AjaxPro ASHX handler
    print("[*] Fetching attendance module...")
    session.headers.update({"Referer": "https://www.webprosindia.com/hitam/StudentMaster.aspx"})
    att_page_resp = session.get(ATTENDANCE_PAGE_URL)
    att_page_soup = BeautifulSoup(att_page_resp.text, "html.parser")

    ashx_url = None
    for s in att_page_soup.find_all("script"):
        src = s.get("src", "")
        if "StudentAttendance" in src and "ashx" in src:
            ashx_url = src
            break

    if not ashx_url:
        ashx_url = "/hitam/ajax/StudentAttendance,App_Web_studentattendance.aspx.a2a1b31c.ashx"

    full_ashx_endpoint = (
        f"https://www.webprosindia.com{ashx_url}?_method=ShowAttendance&_session=r"
        if ashx_url.startswith("/")
        else f"https://www.webprosindia.com/hitam/Academics/{ashx_url}?_method=ShowAttendance&_session=r"
    )

    # AjaxPro call: ShowAttendance(rollNo, fromDate, toDate, subjecttype)
    # subjecttype: 'B' for Both Academic & Non-Academic, 'A' for Academic
    ajax_body = f"rollNo={roll_no}\r\nfromDate=\r\ntoDate=\r\nsubjecttype=B"
    ajax_headers = {
        "Content-Type": "text/plain; charset=utf-8",
        "Referer": ATTENDANCE_PAGE_URL
    }

    print("[*] Requesting live attendance report...")
    report_resp = session.post(full_ashx_endpoint, data=ajax_body, headers=ajax_headers)

    if report_resp.status_code != 200 or not report_resp.text:
        print("[-] Failed to retrieve attendance data.")
        return

    try:
        report_html = eval(report_resp.text.strip())
    except Exception:
        report_html = report_resp.text

    report_soup = BeautifulSoup(report_html, "html.parser")

    # Extract Student Info
    print("\n" + "=" * 65)
    print("                 STUDENT ATTENDANCE REPORT               ")
    print("=" * 65)

    info_rows = report_soup.find_all("tr")
    for r in info_rows:
        cols = [c.get_text(" ", strip=True) for c in r.find_all("td")]
        if len(cols) == 3 and cols[1] == ":":
            print(f" {cols[0]:20}: {cols[2]}")

    # Extract Attendance Tables
    tables = report_soup.find_all("table")
    for tbl in tables:
        rows = tbl.find_all("tr")
        header_text = tbl.get_text()
        if "Subject" in header_text or "Held" in header_text or "Percentage" in header_text:
            print("\n" + "-" * 75)
            for row in rows:
                cols = [c.get_text(" ", strip=True) for c in row.find_all(["th", "td"])]
                if len(cols) >= 4:
                    print(" | ".join(f"{c:^15}" for c in cols))
            print("-" * 75)

if __name__ == "__main__":
    sync_hitam()
