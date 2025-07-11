class FacebookLiveWebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :verifyRequestSignature, only: [:receive]

  #   skip_before_action :verify_authenticity_token - ปิด CSRF token เพื่อให้ Facebook เรียกได้
  # verify method - ใช้สำหรับ Facebook webhook verification challenge
  # receive method - รับ Live events จาก Facebook และส่งต่อไปยัง Service
  # verify_signature - ตรวจสอบลายเซ็นจาก Facebook เพื่อความปลอดภัย

  # GET endpoint สำหรับ Facebook verification
  def verify
    # รับพารามิเตอร์จาก Facebook
    challenge = params["hub.challenge"]
    verify_token = params["hub.verify_token"]

    # ตรวจสอบ verify token ที่ Facebook ส่งมา
    if verify_token == ENV["FACEBOOK_VERIFY_TOKEN"]
      # ส่ง challenge กลับไปยัง Facebook
      render plain: challenge, status: :ok
    else
      # ถ้า verify token ไม่ถูกต้อง ส่ง error
      render plain: "Unauthorized", status: :unauthorized
    end
  end

  # POST endpoint สำหรับรับข้อมูล Live events จาก Facebook
  def receive
    # Rails.logger.info "Received Facebook Live webhook: #{JSON.pretty_generate(webhook_params.to_h)}"

    # ดึง UID ของ user เพื่อใช้ในการดึง access token
    # webhook_params['entry'].first['uid'] if webhook_params['entry'].present? && webhook_params['entry'].first['uid'].present?
    uid = "2926531014188313"
    user = User.find_by(uid: uid) if uid.present?
    access_token = user&.oauth_token

    # เรียกใช้ service ที่จัดการกับ webhook โดยส่ง webhook_params ที่ได้รับจาก Facebook
    FacebookLiveWebhookService.new(webhook_params, access_token).process
    render json: { status: "ok" }, status: :ok
  rescue StandardError => e
    Rails.logger.error "Error processing Facebook Live webhook: #{e.message}"
    render json: { error: "Internal Server Error" }, status: :internal_server_error
  end

  private

  # รับ params ทั้งหมด ไม่ require :object
  def webhook_params
    params.permit! # รับทุก key
  end

  def verifyRequestSignature
    signature = request.headers["X-Hub-Signature-256"]

    # ตรวจสอบว่ามี signature หรือไม่
    unless signature
      Rails.logger.warn "Couldn't find 'X-Hub-Signature-256' in headers."
      return head :unauthorized
    end

    # แยก signature เพื่อดึง hash ออกมา
    elements = signature.split("=")
    signature_hash = elements[1]

    # อ่าน request body
    body = request.body.read

    # สร้าง expected hash โดยใช้ HMAC SHA256
    expected_hash = OpenSSL::HMAC.hexdigest("sha256", ENV["FACEBOOK_APP_SECRET"], body)

    # เปรียบเทียบ signature hash กับ expected hash
    unless signature_hash == expected_hash
      Rails.logger.error "Couldn't validate the request signature."
      return head :unauthorized
    end

    # Reset request body เพื่อให้ controller อื่นใช้ได้
    request.body.rewind
  end
end
