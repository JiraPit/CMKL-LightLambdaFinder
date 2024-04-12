from fastapi import FastAPI, File, UploadFile
from fastapi.middleware.cors import CORSMiddleware
import cv2
import numpy as np

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_headers=["*"],
    allow_methods=["*"],
)
# ---------------------------------------------------[End Points]-------------------------------------------------


@app.get("/")
async def root():
    return {"result": "lambda finder", "status": "success"}


@app.post("/calculate/{unit}/{d_value}/{l_value}")
async def calculate(
    unit: str, d_value: float, l_value: float, file: UploadFile = File(...)
):
    # Read the image file using OpenCV
    contents = await file.read()
    nparr = np.frombuffer(contents, np.uint8)
    image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

    # Detect the circles and the black dots
    circles = []
    base_param1 = 300
    while len(circles) < 1 or base_param1 < 0:
        circles = detect_circles(image, base_param1)
        base_param1 -= 10
    dots = detect_black_dots(image)

    # remove dots inside circles
    dots = [
        dot
        for dot in dots
        if not any(
            [
                dot[0] > circle[0]
                and dot[1] > circle[1]
                and dot[0] + dot[2] < circle[0] + circle[2]
                and dot[1] + dot[3] < circle[1] + circle[3]
                for circle in circles
            ]
        )
    ]

    # Measure the distance between three dots
    focus_dots = dots[:3]
    focus_circle = circles[0]

    # Get the dot in the middle based on the x coordinate
    focus_dots = sorted(focus_dots, key=lambda x: x[0])
    middle_dot = focus_dots[1]

    # Measure the circle diameter and use as a reference
    reference = get_circle_diameter(focus_circle) / 2

    # Measure the distance between left dot and the middle dot, and the right dot and the middle dot
    left_distance = get_distance(
        get_center(focus_dots[0]), get_center(middle_dot), reference
    )
    right_distance = get_distance(
        get_center(focus_dots[2]), get_center(middle_dot), reference
    )

    # Find the average distance
    average_distance = (left_distance + right_distance) / 2

    # Calculate the wavelength
    lamb = calculate_lambda(d_value, average_distance, l_value)
    if unit == "cm":
        lamb = lamb * 1e7
    elif unit == "mm":
        lamb = lamb * 1e6
    elif unit == "m":
        lamb = lamb * 1e9

    return {"result": lamb, "status": "success"}


def detect_black_dots(image):
    grayscale_image = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    _, thresholded_image = cv2.threshold(
        grayscale_image, 50, 255, cv2.THRESH_BINARY_INV
    )
    contours, _ = cv2.findContours(
        thresholded_image, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE
    )
    large_contours = [cnt for cnt in contours if cv2.contourArea(cnt) > 10]
    return [cv2.boundingRect(cnt) for cnt in large_contours]


def detect_circles(image, param1):
    grayscale_image = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    blurred_image = cv2.GaussianBlur(grayscale_image, (9, 9), 5)
    circles = cv2.HoughCircles(
        blurred_image,
        cv2.HOUGH_GRADIENT,
        dp=1.5,
        minDist=100,
        param1=param1,
        param2=30,
        minRadius=10,
    )
    rects = []
    if circles is not None:
        circles = np.round(circles[0, :]).astype("int")
        for x, y, r in circles:
            cv2.circle(image, (x, y), r, (0, 255, 0), 4)
            rects.append((x - r, y - r, 2 * r, 2 * r))
    return rects


def get_distance(point1, point2, reference):
    return (
        np.sqrt((point1[0] - point2[0]) ** 2 + (point1[1] - point2[1]) ** 2) / reference
    )


def get_circle_diameter(circle):
    return circle[2]


def get_center(circle):
    return circle[0] + circle[2] // 2, circle[1] + circle[3] // 2


def calculate_lambda(d, y, length):
    lamb = d * (y / length)
    return lamb
