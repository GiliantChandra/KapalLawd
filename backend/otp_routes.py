from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, validator
from whatsapp_otp import get_otp_service
import os

class SendOTPRequest(BaseModel):
    phone_number: str
    method: str = "whatsapp"
    
    @validator('phone_number')
    def validate_phone(cls, v):
        if not v or len(v.replace('+', '').replace(' ', '')) < 8:
            raise ValueError('Nomor telepon tidak valid')
        return v
    
    @validator('method')
    def validate_method(cls, v):
        if v not in ['whatsapp', 'sms']:
            raise ValueError('Method harus "whatsapp" atau "sms"')
        return v


class VerifyOTPRequest(BaseModel):
    phone_number: str
    otp_code: str
    
    @validator('otp_code')
    def validate_otp(cls, v):
        if not v or len(v) != 6 or not v.isdigit():
            raise ValueError('OTP harus 6 digit angka')
        return v


class SendOTPResponse(BaseModel):
    success: bool
    message: str
    remaining_time: int = 0


class VerifyOTPResponse(BaseModel):
    success: bool
    message: str
    verified: bool


def setup_otp_routes(app: FastAPI):

    @app.post("/send-otp", response_model=SendOTPResponse)
    async def send_otp(request: SendOTPRequest):
        try:
            otp_service = get_otp_service()

            # ✅ FIX 1: Normalisasi nomor DULU sebelum semua operasi
            normalized_phone = otp_service._normalize_phone_number(request.phone_number)

            if request.method == 'whatsapp':
                success, otp, message = otp_service.send_otp_whatsapp(normalized_phone)
            else:
                success, otp, message = otp_service.send_otp_sms(normalized_phone)

            if not success:
                raise HTTPException(status_code=400, detail=message)

            # ✅ FIX 2: Gunakan normalized_phone untuk get_remaining_time
            remaining_time = otp_service.get_remaining_time(normalized_phone)

            return SendOTPResponse(
                success=True,
                message=message,
                remaining_time=remaining_time
            )

        except HTTPException:
            raise  # ✅ FIX 3: Jangan tangkap HTTPException, re-raise langsung
        except ValueError as e:
            raise HTTPException(status_code=400, detail=str(e))
        except Exception as e:
            print(f"Error in send_otp: {str(e)}")
            raise HTTPException(status_code=500, detail=f"Gagal mengirim OTP: {str(e)}")


    @app.post("/verify-otp", response_model=VerifyOTPResponse)
    async def verify_otp(request: VerifyOTPRequest):
        try:
            otp_service = get_otp_service()

            # ✅ Sudah benar — normalisasi sebelum verify
            normalized_phone = otp_service._normalize_phone_number(request.phone_number)
            is_valid, message = otp_service.verify_otp(normalized_phone, request.otp_code)

            return VerifyOTPResponse(
                success=is_valid,
                message=message,
                verified=is_valid
            )

        except Exception as e:
            print(f"Error in verify_otp: {str(e)}")
            raise HTTPException(status_code=500, detail=f"Gagal verifikasi OTP: {str(e)}")


    @app.post("/resend-otp", response_model=SendOTPResponse)
    async def resend_otp(request: SendOTPRequest):
        try:
            otp_service = get_otp_service()

            # ✅ FIX: Normalisasi nomor sebelum resend
            normalized_phone = otp_service._normalize_phone_number(request.phone_number)
            success, message = otp_service.resend_otp(normalized_phone, request.method)

            if not success:
                raise HTTPException(status_code=400, detail=message)

            remaining_time = otp_service.get_remaining_time(normalized_phone)

            return SendOTPResponse(
                success=True,
                message=message,
                remaining_time=remaining_time
            )

        except HTTPException:
            raise
        except ValueError as e:
            raise HTTPException(status_code=400, detail=str(e))
        except Exception as e:
            print(f"Error in resend_otp: {str(e)}")
            raise HTTPException(status_code=500, detail=f"Gagal mengirim ulang OTP: {str(e)}")


    @app.get("/otp-status/{phone_number}")
    async def get_otp_status(phone_number: str):
        try:
            otp_service = get_otp_service()
            normalized_phone = otp_service._normalize_phone_number(phone_number)
            remaining_time = otp_service.get_remaining_time(normalized_phone)

            return {
                "phone_number": normalized_phone,
                "has_otp": normalized_phone in otp_service.otp_store,
                "remaining_time": remaining_time,
                "message": f"OTP berlaku selama {remaining_time} detik" if remaining_time > 0 else "OTP tidak aktif"
            }

        except Exception as e:
            raise HTTPException(status_code=500, detail=str(e))


__all__ = ['setup_otp_routes', 'SendOTPRequest', 'VerifyOTPRequest', 'SendOTPResponse', 'VerifyOTPResponse']