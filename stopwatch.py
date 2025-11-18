from textual.app import App, ComposeResult
from textual.screen import Screen
from textual.widgets import Footer, Header, Button, Static, Input, ProgressBar
from textual.containers import Vertical, Horizontal,ScrollableContainer
from textual import work
import paramiko
import os
local_script_path=["generate_audit_report.sh","security_audit.sh"]
local_config_path=["data_for_report.csv","error_code_table.json"]
intro_text="""
리눅스 서버를 자동으로 점검하고 결과 보고서를 생성합니다. 
보고서는 PDF 또는 MD파일로 확인 가능합니다. 
원하는 서버 접속 방법을 선택해주세요

문의 메일: bc2430@naver.com 

"""

password_text="""
[패스워드로 서버에 접속할 경우]
점검할 서버의 ip와 계정명, 패스워드를 입력하여 접속을 시도합니다.

"""

ssh_text="""
[ssh키로 서버에 접속할 경우]
점검할 서버의 ip와 계정명, ssh 비밀키를 입력하여 접속을 시도합니다.
"""
class IntroScreen(Screen):
    """첫 프로그램 소개 화면"""
    def compose(self) -> ComposeResult:
        yield Header()
        with Vertical(id="intro-container"):
            
            self.widget1 = Static("리눅스 서버 보안 점검 프로그램",expand=True)
            self.widget1.styles.color = "white"
            self.widget1.styles.border = ("heavy","white")
            self.widget1.styles.text_align=("center")
            self.widget1.styles.height = 3 
            yield self.widget1
                
            self.widget2 = Static(intro_text)
            self.widget2.styles.color = "white"
            self.widget2.styles.text_align=("center")
            yield self.widget2

            with Horizontal(id="intro-action-sections"):
                with Vertical(id="left-intro-section", classes="intro-section"):

                    self.widget3=Static(password_text)
                    yield self.widget3
                    self.widget3.styles.text_align=("center")
                    self.widget4=Button("시작하기",id="password_btn",variant="primary")

                    self.widget4.styles.content_align = ("right", "top")
                    yield self.widget4
    
                with Vertical(id="right-intro-section", classes="intro-section"):
                    self.widget5=Static(ssh_text)
                    yield self.widget5
                    self.widget5.styles.text_align=("center")              
                    self.widget6=Button("시작하기",id="ssh_btn",variant="primary")
                    yield self.widget6

        yield Footer()
    
    
    def on_button_pressed(self,event:Button.Pressed) -> None:
        if event.button.id == "password_btn": 
            self.app.push_screen("password_main")
        
      
class PasswordMainScreen(Screen):
    def compose(self) -> ComposeResult:
        yield Header()
        yield Static("서버 접속 정보 입력")
        self.ip_input = Input(placeholder="input ip-address ex)192.168.0.1", type="text",id="ip_addr")
        yield self.ip_input
        self.account_input = Input(placeholder="input account name ", type="text",id="username")
        yield self.account_input
        self.password_input = Input(placeholder="input password ", type="text",id="password")
        yield self.password_input
        yield Button("접속", id="connect_password_btn",variant="primary")
        yield Footer()  

    def on_button_pressed(self,event: Button.Pressed) -> None:
        if event.button.id == "connect_password_btn":
            ip_addr=self.query_one("#ip_addr",Input).value
            username=self.query_one("#username",Input).value
            password=self.query_one("#password",Input).value
    

            
            # ssh.close()  
            # self.app.notify("서버접속")
            self.app.push_screen(ProcessMainScreen(ip_addr=ip_addr,username=username,password=password))
            
              
class ProcessMainScreen(Screen):
    def __init__(self, ip_addr: str, username: str, password: str, **kwargs):
        super().__init__(**kwargs)
        # 전달받은 데이터를 클래스 내부 변수에 저장
        self.ip_addr = ip_addr
        self.username = username
        self.password = password
        
     
    def compose(self) -> ComposeResult:
        yield Header()
        yield ProgressBar(total=100, show_percentage=True, id="progressbar")
        with ScrollableContainer(id="log-scrool"):
            self.log_text="----------점검 로그 시작---------"
            yield Static(self.log_text,id="log_output")
        yield Footer()
    def on_mount(self):
        self.run_audit_process()
        
    def update_log(self,message:str):
        
        def update():
            self.log_text+=f"\n{message}"
            log_widget=self.query_one("#log_output")
            log_widget.update(self.log_text)
        self.call_later(update)
            
    @work(thread=True, exclusive=True)    
    def run_audit_process(self):
        remote_base_path=f"/home/{self.username}/audit_files"
        
        remote_path1=f"{remote_base_path}/scripts"
        remote_path2=f"{remote_base_path}/config"

        progressbar= self.query_one("#progressbar", ProgressBar)
        try:
            self.update_log("ssh 접속을 시도합니다.")
            ssh = paramiko.SSHClient()
            ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
            ssh.connect(hostname=self.ip_addr,username=self.username,password=self.password)
            self.update_log("ssh 접속에 성공했습니다.")

            self.call_later(progressbar.update, total=100, progress=5)

            self.update_log(f"서버로 점검을 위한 프로그램 송신중...")
            ssh.exec_command(f"mkdir -p {remote_path1}")
            ssh.exec_command(f"mkdir -p {remote_path2}")
            sftp=ssh.open_sftp()
            
            for i,filename in enumerate(local_script_path):
                remote_file=f"{remote_path1}/{filename}"
                filename=f"./scripts/{filename}"
                sftp.put(filename,remote_file)
                self.update_log(f"전송완료 - {filename}")
                # self.call_later(progressbar.advance(10+i*5))
                self.call_later(progressbar.update, total=100, progress=10+i*5)
                
            for i,filename in enumerate(local_config_path):
                remote_file=f"{remote_path2}/{filename}"
                filename=f"./config/{filename}"
                
                sftp.put(filename,remote_file)
                self.update_log(f"전송완료 - {filename}")
                # self.call_later(progressbar.advance(10+i*5))
                self.call_later(progressbar.update, total=100, progress=20+i*5)
            
            self.update_log("프로그램 실행 권한 수정중...")
            ssh.exec_command(f"chmod u+x {remote_path1}/generate_audit_report.sh")
            ssh.exec_command(f"chmod u+x {remote_path1}/security_audit.sh")
    
            self.update_log("서버 점검 및 보고서 작성중...")
            ssh.exec_command(f"{remote_path1}/generate_audit_report.sh")
            self.update_log("서버 점검 및 보고서 작성 완료")
            self.call_later(progressbar.update, total=100, progress=50)    
 
            
            
            
            
        except Exception as e:
            self.app.notify(f"알 수 없는 오류 발생: {e}", severity="error") 
        
        
        
        
          
class Security_audit_program(App):
    CSS_PATH = "styles.tcss"
    SCREENS = { 
        "intro":IntroScreen,
        "password_main":PasswordMainScreen,
        # "process_main":ProcessMainScreen 얘는 인자를 받아야 해서 이런식으로 하면 인자를 못줌
               }
    
    def on_mount(self) -> None:
        self.push_screen("intro")

    BINDINGS = [
        ("d", "toggle_dark", "Toggle dark mode"),
        ("q", "quit", "Quit the app") 
    ]



    def action_toggle_dark(self) -> None:
        """An action to toggle dark mode."""
        self.theme = (
            "textual-dark" if self.theme == "textual-light" else "textual-light"
        )





if __name__ == "__main__":
    app = Security_audit_program()
    app.run()



