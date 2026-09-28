import base64
import requests
from bs4 import BeautifulSoup
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.primitives import padding

BASE_URL = "https://www.webprosindia.com/hitam/default.aspx"
ATTENDANCE_PAGE_URL = "https://www.webprosindia.com/hitam/Academics/StudentAttendance.aspx?showtype=SA"
MARKS_PAGE_URL = "https://www.webprosindia.com/hitam/Academics/StudentMarksReport.aspx"
FEE_PAGE_URL = "https://www.webprosindia.com/hitam/FeePayments/studentpayments.aspx"

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

def get_dynamic_ashx(session: requests.Session, page_url: str, keyword: str) -> str:
    """
    Scrapes the dynamic AjaxPro ASHX handler URL from the page scripts.
    """
    session.headers.update({"Referer": "https://www.webprosindia.com/hitam/StudentMaster.aspx"})
    resp = session.get(page_url)
    if resp.status_code != 200:
        return ""
    soup = BeautifulSoup(resp.text, "html.parser")
    for s in soup.find_all("script"):
        src = s.get("src", "")
        if keyword.lower() in src.lower() and "ashx" in src.lower():
            return src
    return ""

def parse_ajaxpro_html(raw_response_text: str) -> str:
    """
    Extracts HTML from AjaxPro string literal response.
    """
    text = raw_response_text.strip()
    if text.startswith("'") and text.endswith("'"):
        try:
            return eval(text)
        except Exception:
            return text[1:-1].replace(r"\'", "'")
    return text

def calculate_safe_bunks(attended: int, held: int) -> int:
    """How many upcoming classes can be skipped while staying >= 75%"""
    surplus = attended - (0.75 * held)
    return int(surplus // 0.75) if surplus > 0 else 0

def calculate_recovery_classes(attended: int, held: int) -> int:
    """How many classes in a row must be attended to reach 75%"""
    import math
    shortage = (0.75 * held) - attended
    return math.ceil(shortage / 0.25) if shortage > 0 else 0

def print_separator(title: str = "", width: int = 80, char: str = "="):
    if title:
        print("\n" + char * width)
        print(f"{title.center(width)}")
        print(char * width)
    else:
        print(char * width)

def fetch_attendance(session: requests.Session, roll_no: str):
    """Fetches, parses, and displays student attendance."""
    print("[*] Fetching live attendance module...")
    ashx_url = get_dynamic_ashx(session, ATTENDANCE_PAGE_URL, "StudentAttendance")
    if not ashx_url:
        ashx_url = "/hitam/ajax/StudentAttendance,App_Web_studentattendance.aspx.a2a1b31c.ashx"

    full_ashx_endpoint = (
        f"https://www.webprosindia.com{ashx_url}?_method=ShowAttendance&_session=r"
        if ashx_url.startswith("/")
        else f"https://www.webprosindia.com/hitam/Academics/{ashx_url}?_method=ShowAttendance&_session=r"
    )

    ajax_body = f"rollNo={roll_no}\r\nfromDate=\r\ntoDate=\r\nsubjecttype=B"
    ajax_headers = {
        "Content-Type": "text/plain; charset=utf-8",
        "Referer": ATTENDANCE_PAGE_URL
    }

    report_resp = session.post(full_ashx_endpoint, data=ajax_body, headers=ajax_headers)
    if report_resp.status_code != 200 or not report_resp.text:
        print("[-] Failed to retrieve attendance data.")
        return

    report_html = parse_ajaxpro_html(report_resp.text)
    report_soup = BeautifulSoup(report_html, "html.parser")

    print_separator("STUDENT ATTENDANCE REPORT")

    # Extract Student Info
    for r in report_soup.find_all("tr"):
        cols = [c.get_text(" ", strip=True) for c in r.find_all("td")]
        if len(cols) == 3 and cols[1] == ":":
            print(f" {cols[0]:20}: {cols[2]}")

    # Extract Attendance Tables
    for tbl in report_soup.find_all("table"):
        header_text = tbl.get_text()
        if "Subject" in header_text and ("Held" in header_text or "Percentage" in header_text):
            rows = tbl.find_all("tr")
            header_str = f"{'#':^4} | {'Subject':<28} | {'Held':^8} | {'Attend':^8} | {'%':^8} | {'Status/Bunks':<14}"
            print("\n" + "-" * len(header_str))
            print(header_str)
            print("-" * len(header_str))

            for row in rows:
                cols = [c.get_text(" ", strip=True) for c in row.find_all(["th", "td"])]
                if len(cols) >= 5:
                    sl = cols[0]
                    subj = cols[1]
                    held_str = cols[2]
                    attend_str = cols[3]
                    pct_str = cols[4]

                    if sl.lower() == "total":
                        print("-" * len(header_str))
                        held = int(held_str) if held_str.isdigit() else 0
                        attend = int(attend_str) if attend_str.isdigit() else 0
                        status = ""
                        if held > 0:
                            if attend / held >= 0.75:
                                bunks = calculate_safe_bunks(attend, held)
                                status = f"Safe: {bunks} bunks"
                            else:
                                needed = calculate_recovery_classes(attend, held)
                                status = f"Need: {needed} classes"
                        print(f"{'TOTAL':<35} | {held_str:^8} | {attend_str:^8} | {pct_str:^8} | {status:<14}")
                        print("-" * len(header_str))
                    elif sl.isdigit():
                        held = int(held_str) if held_str.isdigit() else 0
                        attend = int(attend_str) if attend_str.isdigit() else 0
                        status = "-"
                        if held > 0:
                            if attend / held >= 0.75:
                                bunks = calculate_safe_bunks(attend, held)
                                status = f"Bunk: {bunks}"
                            else:
                                needed = calculate_recovery_classes(attend, held)
                                status = f"Attend: +{needed}"
                        print(f"{sl:^4} | {subj:<28} | {held_str:^8} | {attend_str:^8} | {pct_str:^8} | {status:<14}")
            break

def fetch_marks(session: requests.Session, roll_no: str):
    """Fetches, parses, and displays student marks and SGPA history."""
    print("\n[*] Fetching marks & academic performance...")
    ashx_url = get_dynamic_ashx(session, MARKS_PAGE_URL, "studentmarksreport")
    if not ashx_url:
        ashx_url = "/hitam/ajax/Academics_StudentMarksReport,App_Web_studentmarksreport.aspx.a2a1b31c.ashx"

    endpoint = (
        f"https://www.webprosindia.com{ashx_url}?_method=ShowMarks&_session=r"
        if ashx_url.startswith("/")
        else f"https://www.webprosindia.com/hitam/Academics/{ashx_url}?_method=ShowMarks&_session=r"
    )

    headers = {
        "Content-Type": "text/plain; charset=utf-8",
        "Referer": MARKS_PAGE_URL
    }

    report_resp = session.post(endpoint, data="", headers=headers)
    if report_resp.status_code != 200 or not report_resp.text:
        print("[-] Failed to retrieve marks data.")
        return

    report_html = parse_ajaxpro_html(report_resp.text)
    soup = BeautifulSoup(report_html, "html.parser")

    print_separator("ACADEMIC MARKS & GRADES REPORT")

    # 1. Present Semester Marks (CIE / Mid Exams)
    t0 = soup.find("table")
    if t0:
        header_subjects = []
        exam_data = {}
        for tr in t0.find_all("tr"):
            cols = [c.get_text(" ", strip=True) for c in tr.find_all(["th", "td"])]
            if not cols:
                continue
            if cols[0] == "Subject":
                if not header_subjects:
                    header_subjects = cols[1:]
            else:
                exam_name = cols[0]
                exam_data[exam_name] = cols[1:]

        if header_subjects and exam_data:
            print("\n>> PRESENT SEMESTER MARKS (CONTINUOUS INTERNAL EVALUATION)")
            exams = list(exam_data.keys())
            header_str = f"{'Subject':<20} | " + " | ".join(f"{e:^10}" for e in exams)
            print("-" * len(header_str))
            print(header_str)
            print("-" * len(header_str))

            for idx, subj in enumerate(header_subjects):
                scores = [exam_data[e][idx] if idx < len(exam_data[e]) else "-" for e in exams]
                if any(s != "-" for s in scores):
                    if subj == "Total":
                        print("-" * len(header_str))
                        print(f"{'TOTAL MARKS':<20} | " + " | ".join(f"{s:^10}" for s in scores))
                        print("-" * len(header_str))
                    else:
                        print(f"{subj:<20} | " + " | ".join(f"{s:^10}" for s in scores))

    # 2. Semester Wise SGPA and Credits
    sgpa_tables = [tbl for tbl in soup.find_all("table") if "SGPA" in tbl.get_text(" ", strip=True)]
    if sgpa_tables:
        print("\n>> SEMESTER-WISE RESULTS & SGPA HISTORY")
        header_str = f"{'Semester':<16} | {'SGPA':^10} | {'Credits Earned':^18} | {'Subjects Count':^16}"
        print("-" * len(header_str))
        print(header_str)
        print("-" * len(header_str))

        for idx, tbl in enumerate(sgpa_tables, start=1):
            rows = tbl.find_all("tr")
            if len(rows) >= 2:
                subjects = [c.get_text(" ", strip=True) for c in rows[0].find_all(["th", "td"]) if c.get_text(" ", strip=True) and c.get_text(" ", strip=True) != "SGPA"]
                r1_cells = [c.get_text(" ", strip=True) for c in rows[1].find_all(["th", "td"]) if c.get_text(" ", strip=True)]
                
                sgpa = "N/A"
                for c in r1_cells:
                    try:
                        v = float(c)
                        if 0 <= v <= 10:
                            sgpa = f"{v:.2f}"
                            break
                    except ValueError:
                        pass
                
                credits_info = "Completed"
                for r in rows:
                    for td in r.find_all(["td", "th"]):
                        text = td.get_text(" ", strip=True)
                        if "/" in text and any(ch.isdigit() for ch in text):
                            credits_info = text
                            break

                print(f"{'Semester ' + str(idx):<16} | {sgpa:^10} | {credits_info:^18} | {len(subjects):^16}")
        print("-" * len(header_str))

def fetch_fee_details(session: requests.Session, roll_no: str):
    """Fetches, parses, and displays fee breakdown, payments, and dues."""
    print("\n[*] Fetching fee details & payment history...")
    ashx_url = get_dynamic_ashx(session, FEE_PAGE_URL, "studentpayments")
    if not ashx_url:
        ashx_url = "/hitam/ajax/Feepayments_studentpayments,App_Web_studentpayments.aspx.c49df9d1.ashx"

    endpoint = (
        f"https://www.webprosindia.com{ashx_url}?_method=ShowPaymentsReport&_session=no"
        if ashx_url.startswith("/")
        else f"https://www.webprosindia.com/hitam/FeePayments/{ashx_url}?_method=ShowPaymentsReport&_session=no"
    )

    headers = {
        "Content-Type": "text/plain; charset=utf-8",
        "Referer": FEE_PAGE_URL
    }

    report_resp = session.post(endpoint, data=f"rollNo={roll_no}", headers=headers)
    if report_resp.status_code != 200 or not report_resp.text:
        print("[-] Failed to retrieve fee details.")
        return

    report_html = parse_ajaxpro_html(report_resp.text)
    soup = BeautifulSoup(report_html, "html.parser")

    print_separator("STUDENT FEE CARD & DUES SUMMARY")

    target_table = None
    for tbl in soup.find_all("table"):
        for tr in tbl.find_all("tr"):
            cells = [c.get_text(" ", strip=True) for c in tr.find_all(["th", "td"])]
            if "Sl.No" in cells and "Fee" in cells and "Payable" in cells:
                target_table = tbl
                break
        if target_table:
            break

    if not target_table:
        print("[-] Fee table format not recognized.")
        return

    balance_text = ""
    for tr in target_table.find_all("tr"):
        cols = [c.get_text(" ", strip=True) for c in tr.find_all(["th", "td"])]
        if cols and cols[0] == "Balance":
            balance_text = cols[1] if len(cols) > 1 else ""

    header_str = f"{'#':^5} | {'Fee Particulars':<26} | {'Payable (₹)':^12} | {'Paid (₹)':^12} | {'Due (₹)':^12}"
    print("-" * len(header_str))
    print(header_str)
    print("-" * len(header_str))

    for tr in target_table.find_all("tr"):
        cols = [c.get_text(" ", strip=True) for c in tr.find_all(["th", "td"])]
        if not cols or "Sl.No" in cols or "STUDENT FEE CARD" in " ".join(cols):
            continue
        first = cols[0]
        if first.isdigit() and len(cols) >= 6:
            sl = first
            fee_name = cols[1]
            payable = cols[4] if len(cols) > 4 else cols[2]
            paid = cols[5] if len(cols) > 5 else "0.00"
            due = cols[8] if len(cols) > 8 and cols[8] else "0.00"
            print(f"{sl:^5} | {fee_name:<26} | {payable:^12} | {paid:^12} | {due:^12}")
        elif len(cols) == 3 and cols[0].replace(",", "").replace(".", "").isdigit():
            # Additional payment installment receipt row
            print(f"      | {'  + Paid (Rec: ' + cols[1] + ')':<26} | {'':^12} | {cols[0]:^12} | {'':^12}")
        elif "totals" in first.lower():
            print("-" * len(header_str))
            label = first
            payable = cols[3] if len(cols) > 3 else cols[1]
            paid = cols[4] if len(cols) > 4 else cols[2]
            due = cols[7] if len(cols) > 7 else cols[3]
            print(f"{label:<34} | {payable:^12} | {paid:^12} | {due:^12}")
            print("-" * len(header_str))

    if balance_text:
        print("\n" + "=" * len(header_str))
        print(f" OUTSTANDING BALANCE: {balance_text.upper()}")
        print("=" * len(header_str))

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
    password = input("Enter Password: ").strip()

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

    # 1. Attendance Module
    fetch_attendance(session, roll_no)

    # 2. Marks & Academic Performance Module
    fetch_marks(session, roll_no)

    # 3. Fee Details & Payments Module
    fetch_fee_details(session, roll_no)

    print("\n[+] Synchronization completed successfully!\n")

if __name__ == "__main__":
    sync_hitam()