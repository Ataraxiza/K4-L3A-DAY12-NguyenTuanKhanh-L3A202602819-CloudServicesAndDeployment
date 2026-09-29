# Phiếu Phản Ánh — K4 Level 3A, Ngày 12

> **Bài làm cá nhân.** Trả lời bằng lời của chính bạn, dựa trên những gì bạn
> quan sát được khi chạy code — không sao chép đáp án của người khác.
>
> Cách trả lời: thay dòng `> *Câu trả lời của bạn*` bằng câu trả lời.
> `grade.py` đếm số câu đã trả lời (15 điểm cho 10 câu).
>
> Họ và tên: ..........................  Mã học viên: ..........................

---

### Câu 1 — Fail fast (CP1)

Trong `Settings`, `agent_api_key` không có giá trị mặc định nên app chết ngay
khi khởi động nếu thiếu biến môi trường. Hãy mô tả một tình huống cụ thể mà
việc "chết sớm" này cứu bạn, so với việc để mặc định `"changeme"`.

> Khi deploy production nhưng quên đặt `AGENT_API_KEY`. Không có giá trị mặc định, app dừng ngay và mình phát hiện cấu hình thiếu trước khi nhận traffic. Nếu mặc định là `changeme`, app vẫn chạy với khóa dễ đoán, người khác có thể gọi API bằng khóa đó.

---

### Câu 2 — Log cho máy đọc (CP1)

Chạy service và gọi `/ask` vài lần. Dán một dòng log JSON bạn thu được, rồi
nêu **hai** việc bạn làm được với dòng log đó mà `print("đã trả lời xong")`
không làm được.

> {"answer":"Câu hỏi hay. test thường được giải quyết bằng cách chuẩn hóa môi trường chạy: cùng một image chạy giống nhau ở laptop và trên cloud. (Mình đang nhớ 20 lượt trao đổi trước đó.)","user_id":"sv-test","history_length":20,"cost_usd":9.3e-05,"tokens":{"in":448,"out":43}} Dòng log JSON này cho phép tôi: 1. Lọc và tìm kiếm theo các trường cụ thể, ví dụ user_id, để xem lịch sử request của từng user; 2. Thống kê và phân tích các trường số như cost_usd, tokens.in, tokens.out để theo dõi chi phí và mức sử dụng token. Ở chiều ngược lại, print("đã trả lời xong") chỉ ghi một chuỗi text đơn giản, không có các trường dữ liệu có cấu trúc để dễ dàng lọc hoặc thống kê tự động.

---

### Câu 3 — Kích thước image (CP2)

Build cả hai phiên bản và ghi lại số đo thật:

```bash
docker build -f <Dockerfile-1-stage> -t agent:single .
docker build -t agent:multi .
docker images | grep agent
```

| Bản | Dung lượng |
|-----|-----------|
| 1 stage (bản đầu) | 716 MB |
| Multi-stage | 271 MB |

Giải thích: phần dung lượng chênh lệch đó là những gì?

> Single-stage: Build tools như build-essential được giữ lại trong image production, nên image lớn hơn (716 MB). Multi-stage: Build tools chỉ tồn tại trong builder stage và không được copy sang runtime stage, nên image production nhỏ hơn (271 MB).

---

### Câu 4 — Thứ tự lệnh trong Dockerfile (CP2)

Sửa một ký tự trong `app/main.py` rồi build lại. Với Dockerfile của bạn, những
layer nào được dùng lại từ cache, layer nào phải chạy lại? Nếu bạn đặt
`COPY . .` lên trước `RUN pip install` thì kết quả khác thế nào?

> Khi sửa một ký tự trong app/main.py rồi build lại, Docker sẽ sử dụng lại các layer đã được cache từ FROM python:3.11-slim đến RUN pip install, vì requirements.txt không thay đổi. Các layer COPY app ./app và các layer phía sau phải chạy lại vì nội dung source code đã thay đổi. Dockerfile hiện tại được sắp xếp như vậy để tận dụng cache: các dependency chỉ được cài lại khi requirements.txt thay đổi. Nếu đặt COPY . . trước RUN pip install, chỉ cần thay đổi một file source như app/main.py thì layer COPY . . cũng thay đổi. Khi đó Docker sẽ phải chạy lại RUN pip install, dù requirements.txt không thay đổi. Điều này làm thời gian build lâu hơn và sử dụng cache kém hiệu quả hơn.

---

### Câu 5 — Vì sao không chạy bằng root (CP2)

Container mặc định chạy bằng root. Mô tả chuỗi sự kiện dẫn từ "một lỗ hổng
trong code Python của bạn" tới "kẻ tấn công có quyền cao trên máy host", và
lệnh `USER` cắt đứt chuỗi đó ở chỗ nào.

> Một lỗ hổng trong code Python có thể cho phép kẻ tấn công thực thi mã bên trong container. Nếu container chạy bằng root, mã độc đó sẽ có quyền root trong container. Nếu container còn có cấu hình không an toàn như mount Docker socket, mount filesystem của host hoặc các quyền đặc biệt, kẻ tấn công có thể lợi dụng chúng để thoát khỏi container và tiếp cận máy host với quyền cao. Lệnh USER appuser cắt đứt chuỗi này ở bước quyền bên trong container: ngay cả khi khai thác được lỗ hổng và thực thi mã, tiến trình ứng dụng chỉ có quyền của appuser, không phải root. Điều này làm giảm đáng kể khả năng kẻ tấn công thực hiện các thao tác đặc quyền hoặc tiếp tục khai thác container để ảnh hưởng đến host.

---

### Câu 6 — Cửa sổ trượt (CP3)

Rate limit của bạn dùng sliding window 60 giây. Nếu thay bằng cách đếm theo
phút đồng hồ (reset lúc giây 00), một người dùng có thể gửi tối đa bao nhiêu
request trong 2 giây liên tiếp khi hạn mức là 10/phút? Giải thích cách đạt được
con số đó.

> Nếu dùng cách đếm theo phút đồng hồ và giới hạn là 10 request/phút, một người dùng có thể gửi tối đa 20 request trong 2 giây liên tiếp. Ví dụ, gửi 10 request ngay trước thời điểm chuyển sang phút mới, chẳng hạn từ giây 59 đến 59.9. Khi đồng hồ chuyển sang phút mới, bộ đếm được reset và người dùng có thể gửi thêm 10 request ngay sau giây 00. Vì vậy trong khoảng thời gian khoảng 2 giây có thể gửi tổng cộng 20 request. Sliding window 60 giây tránh hiện tượng này vì nó xét 60 giây thực tế gần nhất thay vì ranh giới phút đồng hồ.

---

### Câu 7 — Rate limit và cost guard (CP3)

Hai cơ chế này khác nhau ở điểm nào? Cho một tình huống mà rate limit cho qua
nhưng cost guard phải chặn, và một tình huống ngược lại.

> Rate limit giới hạn số lượng request trong một khoảng thời gian, còn cost guard giới hạn chi phí hoặc ngân sách sử dụng của user. Ví dụ rate limit cho qua nhưng cost guard chặn: user mới chỉ gửi vài request nên chưa vượt giới hạn request/phút, nhưng mỗi request sử dụng rất nhiều token khiến chi phí đã vượt ngân sách tháng. Ngược lại, rate limit có thể chặn nhưng cost guard chưa chặn: user gửi rất nhiều request nhỏ trong thời gian ngắn nên vượt giới hạn request/phút, nhưng tổng chi phí vẫn còn thấp hơn ngân sách cho phép.

---

### Câu 8 — /health khác /ready (CP4)

Nếu gộp hai endpoint làm một và cho nó kiểm tra Redis, chuyện gì xảy ra với cụm
3 container khi Redis mất kết nối 30 giây? Trả lời theo đúng thứ tự sự kiện.

> Nếu gộp /health và /ready thành một endpoint và endpoint đó kiểm tra Redis, khi Redis mất kết nối trong 30 giây, chuỗi sự kiện sẽ là: Redis mất kết nối -> Cả 3 container đều kiểm tra Redis và endpoint trả về trạng thái không khỏe -> Orchestrator coi cả 3 container là unhealthy -> Orchestrator restart cả 3 container cùng lúc -> Trong lúc cả 3 container đang restart, không còn container nào phục vụ request -> Redis có thể quay lại, nhưng lúc đó toàn bộ service đã bị restart cùng lúc -> Đây là lý do /health và /ready cần tách biệt: /health chỉ kiểm tra process còn sống, còn /ready kiểm tra Redis để load balancer ngừng gửi traffic đến instance chưa sẵn sàng mà không khiến orchestrator restart container.
---

### Câu 9 — Stateless (CP4)

Chạy `docker compose up --scale agent=3` rồi gọi `/ask` nhiều lần với cùng một
`X-User-Id`. Quan sát `history_length` trong response. Nếu lịch sử được lưu
trong một dict Python thay vì Redis, bạn sẽ thấy con số đó thay đổi thế nào?

> Nếu dùng một dict Python trong mỗi container, lịch sử chỉ tồn tại trong RAM của instance đã nhận request. Với cùng `X-User-Id`, khi request được chuyển sang instance khác, `history_length` có thể quay về 0 hoặc thấp hơn instance trước; nếu quay lại instance cũ thì con số lại tiếp tục tăng ở đó. Vì vậy kết quả sẽ không tăng đều giữa các request. Redis giúp cả ba instance đọc chung một lịch sử.

---

### Câu 10 — Deploy thật (CP5)

Ghi lại **một** lỗi bạn gặp khi deploy lên cloud (build fail, health check
timeout, sai REDIS_URL, app không đọc `$PORT`...): thông báo lỗi là gì, bạn
tìm ra nguyên nhân bằng cách nào, và sửa ra sao?

> Khi deploy Railway, `/ready` trả 503 và log agent báo `TimeoutError: Timeout connecting to server`. Mình kiểm tra bằng `railway logs --service Redis --environment production --lines 60`; log Redis lặp lại `/bin/sh: 1: exec: docker-entrypoint.sh: not found`. Mình cũng kiểm tra DNS và thấy `redis.railway.internal` phân giải được, nên lỗi nằm ở Redis service không khởi động đúng. Sau đó mình đã xoá Start Command sai ở cấu hình Redis trên Railway, deploy lại Redis, rồi kiểm tra `/ready` thì kết quả trả về 200 (hết lỗi).
