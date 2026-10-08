"use strict";

const form = document.getElementById("prediction-form");
const provinceSelect = document.getElementById("province");
const districtSelect = document.getElementById("district");
const submitButton = document.getElementById("submit-button");
const formError = document.getElementById("form-error");
const optionsError = document.getElementById("options-error");
const optionsErrorText = document.getElementById("options-error-text");
const historyList = document.getElementById("history-list");
const clearHistoryButton = document.getElementById("clear-history");
const historyKey = "housevalue.predictions.v1";
const priceFormat = new Intl.NumberFormat("vi-VN", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
const dateFormat = new Intl.DateTimeFormat("vi-VN", { dateStyle: "short", timeStyle: "short" });

let provinces = [];

function setOptions(select, options, placeholder) {
  select.replaceChildren(new Option(placeholder, ""));
  for (const item of options) select.add(new Option(item.label, item.code));
  select.disabled = options.length === 0;
}

function selectedProvince() {
  return provinces.find((item) => item.code === provinceSelect.value);
}

function updateDistricts() {
  const province = selectedProvince();
  setOptions(districtSelect, province?.districts ?? [], province ? "Chọn quận / huyện" : "Chọn tỉnh / thành phố trước");
}

async function requestJson(url, init = {}) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 45000);
  try {
    const response = await fetch(url, { ...init, signal: controller.signal });
    const data = await response.json();
    if (!response.ok) {
      const field = data?.error?.fields?.[0];
      throw new Error(field ? `${field.field}: ${field.message}` : data?.error?.message || `Máy chủ trả về lỗi ${response.status}.`);
    }
    return data;
  } catch (error) {
    if (error.name === "AbortError") throw new Error("Máy chủ phản hồi quá chậm. Vui lòng thử lại.");
    if (error instanceof TypeError) throw new Error("Không thể kết nối máy chủ. Vui lòng kiểm tra Internet.");
    throw error;
  } finally {
    clearTimeout(timer);
  }
}

async function loadOptions() {
  optionsError.hidden = true;
  submitButton.disabled = true;
  setOptions(provinceSelect, [], "Đang tải địa điểm...");
  updateDistricts();
  try {
    const data = await requestJson("/api/v1/options");
    provinces = data.provinces ?? [];
    setOptions(provinceSelect, provinces, "Chọn tỉnh / thành phố");
    updateDistricts();
    submitButton.disabled = provinces.length === 0;
    if (provinces.length === 0) throw new Error("Danh sách địa điểm đang trống.");
  } catch (error) {
    optionsErrorText.textContent = error.message;
    optionsError.hidden = false;
  }
}

function parseNumber(value, label, maximum, integer = false) {
  const raw = value.trim();
  if (!raw) return null;
  const normalized = raw.replace(",", ".");
  const validFormat = integer ? /^\d+$/.test(normalized) : /^\d+(?:\.\d+)?$/.test(normalized);
  const number = Number(normalized);
  if (!validFormat || !Number.isFinite(number) || number <= 0 || number > maximum) {
    throw new Error(`${label} phải là ${integer ? "số nguyên" : "số"} lớn hơn 0 và không quá ${maximum}.`);
  }
  return number;
}

function createPayload() {
  const values = new FormData(form);
  const area = parseNumber(values.get("area_m2"), "Diện tích", 5000);
  if (area === null) throw new Error("Vui lòng nhập diện tích.");
  if (!provinceSelect.value || !districtSelect.value) throw new Error("Vui lòng chọn tỉnh / thành phố và quận / huyện.");
  return {
    area_m2: area,
    frontage_m: parseNumber(values.get("frontage_m"), "Mặt tiền", 500),
    access_road_width_m: parseNumber(values.get("access_road_width_m"), "Đường vào", 500),
    floors: parseNumber(values.get("floors"), "Số tầng", 100, true),
    bedrooms: parseNumber(values.get("bedrooms"), "Phòng ngủ", 100, true),
    bathrooms: parseNumber(values.get("bathrooms"), "Phòng tắm", 100, true),
    house_direction: values.get("house_direction") || null,
    balcony_direction: values.get("balcony_direction") || null,
    legal_status: values.get("legal_status") || null,
    furniture_state: values.get("furniture_state") || null,
    province_code: provinceSelect.value,
    district_code: districtSelect.value,
  };
}

function showResult(item) {
  document.getElementById("result-empty").hidden = true;
  document.getElementById("result-content").hidden = false;
  document.getElementById("price-value").textContent = priceFormat.format(item.price);
  document.getElementById("model-version").textContent = item.modelVersion;
  document.getElementById("prediction-id").textContent = item.id;
  const warningContainer = document.getElementById("warnings");
  warningContainer.replaceChildren();
  for (const warning of item.warnings ?? []) {
    const element = document.createElement("div");
    element.className = "warning";
    element.textContent = warning.message;
    warningContainer.append(element);
  }
  document.getElementById("result").scrollIntoView({ behavior: "smooth", block: "nearest" });
}

function readHistory() {
  try {
    const saved = JSON.parse(localStorage.getItem(historyKey) || "[]");
    return Array.isArray(saved) ? saved : [];
  } catch {
    return [];
  }
}

function saveHistory(items) {
  try { localStorage.setItem(historyKey, JSON.stringify(items)); } catch { /* Storage may be disabled. */ }
}

function renderHistory() {
  const items = readHistory();
  historyList.replaceChildren();
  clearHistoryButton.hidden = items.length === 0;
  if (items.length === 0) {
    const empty = document.createElement("p");
    empty.className = "history-empty";
    empty.textContent = "Chưa có kết quả nào. Hãy thử định giá bất động sản đầu tiên.";
    historyList.append(empty);
    return;
  }
  for (const item of items) {
    const button = document.createElement("button");
    button.type = "button";
    button.className = "history-item";
    const place = document.createElement("span");
    place.className = "history-place";
    place.textContent = item.place || "Bất động sản";
    const meta = document.createElement("span");
    meta.className = "history-meta";
    meta.textContent = `${item.area} m² · ${dateFormat.format(new Date(item.createdAt))}`;
    const price = document.createElement("span");
    price.className = "history-price";
    price.textContent = `${priceFormat.format(item.price)} `;
    const unit = document.createElement("small");
    unit.textContent = "tỷ VNĐ";
    price.append(unit);
    button.append(place, meta, price);
    button.addEventListener("click", () => showResult(item));
    historyList.append(button);
  }
}

form.addEventListener("submit", async (event) => {
  event.preventDefault();
  formError.hidden = true;
  let payload;
  try {
    payload = createPayload();
  } catch (error) {
    formError.textContent = error.message;
    formError.hidden = false;
    return;
  }
  submitButton.disabled = true;
  submitButton.firstChild.textContent = "Đang phân tích... ";
  try {
    const data = await requestJson("/api/v1/predictions", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
    const item = {
      id: data.prediction_id,
      price: data.estimated_price.value,
      modelVersion: data.model.version,
      warnings: data.warnings,
      place: `${districtSelect.selectedOptions[0].textContent}, ${provinceSelect.selectedOptions[0].textContent}`,
      area: payload.area_m2,
      createdAt: new Date().toISOString(),
    };
    showResult(item);
    saveHistory([item, ...readHistory()].slice(0, 50));
    renderHistory();
  } catch (error) {
    formError.textContent = error.message;
    formError.hidden = false;
  } finally {
    submitButton.disabled = false;
    submitButton.firstChild.textContent = "Ước tính giá nhà ";
  }
});

provinceSelect.addEventListener("change", updateDistricts);
document.getElementById("retry-options").addEventListener("click", loadOptions);
clearHistoryButton.addEventListener("click", () => {
  if (window.confirm("Xóa toàn bộ lịch sử định giá trên trình duyệt này?")) {
    try { localStorage.removeItem(historyKey); } catch { /* Storage may be disabled. */ }
    renderHistory();
  }
});

renderHistory();
loadOptions();
